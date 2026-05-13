<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Operations\Http\Resources\IncomeOperationResource;
use App\Modules\Operations\Http\Resources\ReportOperationResource;
use App\Modules\Operations\Http\Resources\TransferOperationResource;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Operations\Models\TransferOperation;
use App\Modules\Projects\Models\Project;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

/**
 * Объединённая история TRANSFER + INCOME + REPORT для экрана «История операций» (ТЗ-06.1 / ТЗ-10C).
 *
 * Параметр tab:
 * - pending: только операции, где у текущего участника есть «шаг на подтверждение»
 *   (см. TransferAvailableActionsService / IncomeAvailableActionsService::hasPendingConfirmationAction).
 *   Список ключей должен совпадать с бейджем pending на главном экране: например, этап
 *   WAITING_24_HOURS и «чистый откат» (reset_approval у INCOME) туда не входят — см. константы
 *   PENDING_BADGE_* в available-actions сервисах.
 * - all: «все операции» — для OWNER компании в company-workspace все операции компании;
 *   иначе только операции, где пользователь участвовал в строке операции (не «весь проект»).
 */
final class AggregatedOperationsHistoryService
{
    public function __construct(
        private readonly OperationVisibilityService $operationVisibility,
        private readonly IncomeVisibilityService $incomeVisibility,
        private readonly ReportVisibilityService $reportVisibility,
        private readonly TransferAvailableActionsService $transferAvailableActions,
        private readonly IncomeAvailableActionsService $incomeAvailableActions,
        private readonly ReportAvailableActionsService $reportAvailableActions,
    ) {}

    /**
     * @param iterable<int, Project> $projects
     *
     * @return array{items: array<int, array<string, mixed>>, total: int}
     */
    public function paginate(
        iterable $projects,
        int $userId,
        ?int $companyWorkspaceId,
        string $tab,
        int $perPage,
        int $page,
    ): array {
        $tab = in_array($tab, ['pending', 'all'], true) ? $tab : 'all';

        if ($tab === 'pending') {
            return $this->paginatePending($projects, $userId, $perPage, $page);
        }

        return $this->paginateAllUnion($projects, $userId, $companyWorkspaceId, $perPage, $page);
    }

    /**
     * @param iterable<int, Project> $projects
     *
     * @return array{items: array<int, array<string, mixed>>, total: int}
     */
    private function paginateAllUnion(
        iterable $projects,
        int $userId,
        ?int $companyWorkspaceId,
        int $perPage,
        int $page,
    ): array {
        $projects = is_array($projects) ? $projects : iterator_to_array($projects);

        if ($this->isCompanyOwnerInWorkspace($userId, $companyWorkspaceId)) {
            $companyId = (int) $companyWorkspaceId;
            $tq = TransferOperation::query()
                ->whereHas('project', static fn (Builder $q) => $q->where('company_id', $companyId))
                ->select([
                    DB::raw("'transfer' as operation_kind"),
                    'transfer_operations.id as operation_row_id',
                    $this->sortAtSql('transfer_operations'),
                    'transfer_operations.project_id',
                ]);

            $iq = IncomeOperation::query()
                ->whereHas('project', static fn (Builder $q) => $q->where('company_id', $companyId))
                ->select([
                    DB::raw("'income' as operation_kind"),
                    'income_operations.id as operation_row_id',
                    $this->sortAtSql('income_operations'),
                    'income_operations.project_id',
                ]);

            $rq = ReportOperation::query()
                ->where('company_id', $companyId)
                ->select([
                    DB::raw("'report' as operation_kind"),
                    'report_operations.id as operation_row_id',
                    $this->sortAtSql('report_operations'),
                    'report_operations.project_id',
                ]);
        } else {
            if ($projects === []) {
                return ['items' => [], 'total' => 0];
            }

            $tq = $this->operationVisibility
                ->transferQueryParticipationOnlyAcrossProjects($projects, $userId)
                ->select([
                    DB::raw("'transfer' as operation_kind"),
                    'transfer_operations.id as operation_row_id',
                    $this->sortAtSql('transfer_operations'),
                    'transfer_operations.project_id',
                ]);

            $iq = $this->incomeVisibility
                ->incomeQueryParticipationOnlyAcrossProjects($projects, $userId)
                ->select([
                    DB::raw("'income' as operation_kind"),
                    'income_operations.id as operation_row_id',
                    $this->sortAtSql('income_operations'),
                    'income_operations.project_id',
                ]);

            $rq = $this->reportVisibility
                ->reportQueryParticipationOnlyAcrossProjects($projects, $userId)
                ->select([
                    DB::raw("'report' as operation_kind"),
                    'report_operations.id as operation_row_id',
                    $this->sortAtSql('report_operations'),
                    'report_operations.project_id',
                ]);
        }

        $union = $tq->unionAll($iq)->unionAll($rq);

        $total = (int) DB::query()->fromSub($union, 'merged')->count();

        $offset = max(0, ($page - 1) * $perPage);

        $rows = DB::query()
            ->fromSub($union, 'merged')
            ->orderByDesc('operation_sort_at')
            ->orderByDesc('operation_row_id')
            ->offset($offset)
            ->limit($perPage)
            ->get();

        return ['items' => $this->hydrateRows($rows), 'total' => $total];
    }

    /**
     * @param iterable<int, Project> $projects
     *
     * @return array{items: array<int, array<string, mixed>>, total: int}
     */
    private function paginatePending(iterable $projects, int $userId, int $perPage, int $page): array
    {
        $projects = is_array($projects) ? $projects : iterator_to_array($projects);

        /** @var list<array{kind: string, id: int, sort: int}> $candidates */
        $candidates = [];

        foreach ($projects as $project) {
            $transferParticipant = $this->operationVisibility->participantForUser($project, $userId);
            if ($transferParticipant !== null) {
                $q = $this->operationVisibility
                    ->transferQueryForUser($project, $userId)
                    ->with('initiator');
                foreach ($q->cursor() as $transfer) {
                    if ($this->transferAvailableActions->hasPendingConfirmationAction($transferParticipant, $transfer)) {
                        $candidates[] = $this->candidateRow('transfer', (int) $transfer->id, $transfer->updated_at, $transfer->created_at);
                    }
                }
            }

            $incomeParticipant = $this->incomeVisibility->participantForUser($project, $userId);
            if ($incomeParticipant !== null) {
                $q = $this->incomeVisibility
                    ->incomeQueryForUser($project, $userId)
                    ->with('initiator');
                foreach ($q->cursor() as $income) {
                    if ($this->incomeAvailableActions->hasPendingConfirmationAction($incomeParticipant, $income)) {
                        $candidates[] = $this->candidateRow('income', (int) $income->id, $income->updated_at, $income->created_at);
                    }
                }
            }

            $reportParticipant = $this->reportVisibility->participantForUser($project, $userId);
            if ($reportParticipant !== null) {
                $q = $this->reportVisibility
                    ->reportQueryForUser($project, $userId)
                    ->with('initiator');
                foreach ($q->cursor() as $report) {
                    if ($this->reportAvailableActions->hasPendingConfirmationAction($reportParticipant, $report)) {
                        $candidates[] = $this->candidateRow('report', (int) $report->id, $report->updated_at, $report->created_at);
                    }
                }
            }
        }

        usort($candidates, static function (array $a, array $b): int {
            if ($a['sort'] !== $b['sort']) {
                return $b['sort'] <=> $a['sort'];
            }

            return $b['id'] <=> $a['id'];
        });

        $total = count($candidates);
        $offset = max(0, ($page - 1) * $perPage);
        $slice = array_slice($candidates, $offset, $perPage);

        $rows = array_map(static function (array $c): object {
            return (object) [
                'operation_kind' => $c['kind'],
                'operation_row_id' => $c['id'],
                'operation_sort_at' => $c['sort'],
                'project_id' => 0,
            ];
        }, $slice);

        return ['items' => $this->hydrateRows($rows), 'total' => $total];
    }

    /**
     * @param \Illuminate\Support\Collection<int, object>|iterable<int, object> $rows
     *
     * @return array<int, array<string, mixed>>
     */
    private function hydrateRows(iterable $rows): array
    {
        $items = [];

        foreach ($rows as $row) {
            $kind = (string) $row->operation_kind;
            $id = (int) $row->operation_row_id;

            if ($kind === 'transfer') {
                $t = TransferOperation::query()
                    ->with(['sender.counterparty.user', 'receiver.counterparty.user', 'project'])
                    ->find($id);
                if ($t !== null) {
                    $items[] = [
                        'operation_kind' => 'transfer',
                        'project_id' => (int) $t->project_id,
                        'transfer' => (new TransferOperationResource($t))->resolve(),
                    ];
                }
            } elseif ($kind === 'income') {
                $i = IncomeOperation::query()
                    ->with([
                        'initiator.counterparty.user',
                        'projectHead.counterparty.user',
                        'customer.counterparty.user',
                        'project',
                    ])
                    ->find($id);
                if ($i !== null) {
                    $items[] = [
                        'operation_kind' => 'income',
                        'project_id' => (int) $i->project_id,
                        'income' => (new IncomeOperationResource($i))->resolve(),
                    ];
                }
            } elseif ($kind === 'report') {
                $r = ReportOperation::query()
                    ->with([
                        'initiator.counterparty.user',
                        'recipientParticipant.counterparty.user',
                        'customerParticipant.counterparty.user',
                        'project',
                    ])
                    ->find($id);
                if ($r !== null) {
                    $items[] = [
                        'operation_kind' => 'report',
                        'project_id' => (int) $r->project_id,
                        'report' => (new ReportOperationResource($r))->resolve(),
                    ];
                }
            }
        }

        return $items;
    }

    /**
     * Для сортировки ленты: более поздняя из created_at / updated_at.
     * SQLite (тесты): без GREATEST; PostgreSQL / MySQL: GREATEST.
     */
    private function sortAtSql(string $table): \Illuminate\Contracts\Database\Query\Expression
    {
        if (DB::getDriverName() === 'sqlite') {
            return DB::raw(
                "(CASE WHEN {$table}.updated_at >= {$table}.created_at THEN {$table}.updated_at ELSE {$table}.created_at END) as operation_sort_at",
            );
        }

        return DB::raw("GREATEST({$table}.updated_at, {$table}.created_at) as operation_sort_at");
    }

    private function candidateRow(string $kind, int $id, ?\DateTimeInterface $updatedAt, ?\DateTimeInterface $createdAt): array
    {
        $tu = $updatedAt?->getTimestamp() ?? 0;
        $tc = $createdAt?->getTimestamp() ?? 0;

        return ['kind' => $kind, 'id' => $id, 'sort' => max($tu, $tc)];
    }

    private function isCompanyOwnerInWorkspace(int $userId, ?int $companyWorkspaceId): bool
    {
        if ($companyWorkspaceId === null) {
            return false;
        }

        return Counterparty::query()
            ->where('company_id', $companyWorkspaceId)
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->where('company_role_code', CompanyRoleCode::OWNER->value)
            ->exists();
    }
}
