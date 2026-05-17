<?php

declare(strict_types=1);

namespace App\Modules\Workspaces\Services;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\TransferTargetType;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Operations\Models\ReportWalletDelta;
use App\Modules\Operations\Models\TransferOperation;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Аналитика главного экрана company-workspace (OWNER / PARTNER). См. docs/90_current/TZ_Company_Dashboard_Analytics_Report_Transfer.md.
 */
final class CompanyDashboardAnalyticsService
{
    public function build(int $companyId, int $userId, ?string $selectedMonthYyyyMm, Carbon $nowUtc): array
    {
        $cp = Counterparty::query()
            ->where('company_id', $companyId)
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->firstOrFail();

        $role = (string) $cp->company_role_code;
        $isOwner = $role === CompanyRoleCode::OWNER->value;

        $quarter = $this->quarterBounds($nowUtc);
        $participantIdsCompany = $this->participantIdsForCompany($companyId);
        $participantIdsUser = $this->participantIdsForCounterparty($companyId, (int) $cp->id);

        $monthStart = null;
        $monthEnd = null;
        if ($selectedMonthYyyyMm !== null && $selectedMonthYyyyMm !== '') {
            $monthStart = Carbon::createFromFormat('Y-m', $selectedMonthYyyyMm, 'UTC')->startOfMonth();
            $monthEnd = (clone $monthStart)->endOfMonth();
            if ($monthEnd->gt($nowUtc)) {
                $monthEnd = $nowUtc->copy();
            }
        }

        $asOf = $monthStart !== null ? $monthEnd : $nowUtc;

        if ($isOwner) {
            $incomeFlowStart = $monthStart ?? $quarter['start'];
            $incomeFlowEnd = $monthStart !== null ? $monthEnd : $nowUtc;

            $incomeTotal = $this->ownerIncomeFlowInRange($companyId, $incomeFlowStart, $incomeFlowEnd);
            ['debt' => $debt, 'overpayment' => $overpayment] = $this->debtOverpaymentTotalsMoney(
                $companyId,
                $participantIdsCompany,
                $asOf,
            );

            $activeProjectsNow = $this->countActiveProjectsOwner($companyId, $nowUtc);
            $monthsPayload = [];
            foreach ($quarter['months'] as $mStart) {
                $monthsPayload[] = $this->monthSliceOwner(
                    $companyId,
                    $participantIdsCompany,
                    $mStart,
                    $nowUtc,
                );
            }

            return [
                'matrix_role'           => 'owner',
                'selected_month'        => $selectedMonthYyyyMm,
                'income_total'          => $this->formatMoney($incomeTotal),
                'debt_total'            => $debt,
                'overpayment_total'     => $overpayment,
                'active_projects_total' => $activeProjectsNow,
                'quarter'               => [
                    'year'        => $quarter['start']->year,
                    'start_month' => $quarter['start']->month,
                    'months'      => $monthsPayload,
                ],
            ];
        }

        // PARTNER (и прочие роли компании — тот же финансовый контур «личные участники»).
        $incomeFlowStart = $monthStart ?? $quarter['start'];
        $incomeFlowEnd = $monthStart !== null ? $monthEnd : $nowUtc;
        $incomeTotal = $this->partnerIncomeTransferFlowInRange($participantIdsUser, $incomeFlowStart, $incomeFlowEnd);

        ['debt' => $debt, 'overpayment' => $overpayment] = $this->debtOverpaymentTotalsMoney(
            $companyId,
            $participantIdsUser,
            $asOf,
        );

        $activeProjectsNow = $this->countActiveProjectsPartnerHead($companyId, (int) $cp->id, $nowUtc);
        $monthsPayload = [];
        foreach ($quarter['months'] as $mStart) {
            $monthsPayload[] = $this->monthSlicePartner(
                $companyId,
                (int) $cp->id,
                $participantIdsUser,
                $mStart,
                $nowUtc,
            );
        }

        return [
            'matrix_role'           => 'partner',
            'selected_month'        => $selectedMonthYyyyMm,
            'income_total'          => $this->formatMoney($incomeTotal),
            'debt_total'            => $debt,
            'overpayment_total'     => $overpayment,
            'active_projects_total' => $activeProjectsNow,
            'quarter'               => [
                'year'        => $quarter['start']->year,
                'start_month' => $quarter['start']->month,
                'months'      => $monthsPayload,
            ],
        ];
    }

    /**
     * Карточки операций для bottom sheet аналитики (см. ТЗ dashboard analytics operations).
     *
     * @return list<array<string, mixed>>
     */
    public function listOperations(
        int $companyId,
        int $userId,
        string $metric,
        ?string $monthYyyyMm,
        Carbon $nowUtc,
    ): array {
        $cp = Counterparty::query()
            ->where('company_id', $companyId)
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->firstOrFail();

        $isOwner = (string) $cp->company_role_code === CompanyRoleCode::OWNER->value;
        $participantIdsCompany = $this->participantIdsForCompany($companyId);
        $participantIdsUser = $this->participantIdsForCounterparty($companyId, (int) $cp->id);

        $quarter = $this->quarterBounds($nowUtc);
        if ($monthYyyyMm !== null && $monthYyyyMm !== '') {
            $rangeStart = Carbon::createFromFormat('Y-m', $monthYyyyMm, 'UTC')->startOfMonth();
            $rangeEnd = (clone $rangeStart)->endOfMonth();
            if ($rangeEnd->gt($nowUtc)) {
                $rangeEnd = $nowUtc->copy();
            }
        } else {
            $rangeStart = $quarter['start'];
            $rangeEnd = $nowUtc->copy();
        }

        return match ($metric) {
            'income' => $isOwner
                ? $this->buildOwnerIncomeOperationCards($companyId, $rangeStart, $rangeEnd)
                : $this->buildPartnerIncomeOperationCards($participantIdsUser, $rangeStart, $rangeEnd),
            'debt' => $isOwner
                ? $this->buildDebtReportOperationCards($companyId, $participantIdsCompany, $rangeEnd)
                : $this->buildDebtReportOperationCards($companyId, $participantIdsUser, $rangeEnd),
            'overpayment' => $isOwner
                ? $this->buildOverpaymentAggregateOperationCards($companyId, $participantIdsCompany, $rangeEnd)
                : $this->buildOverpaymentAggregateOperationCards($companyId, $participantIdsUser, $rangeEnd),
            default => [],
        };
    }

    /**
     * Детализация агрегата «Переплата по проекту»: сводка, список переводов и отчётов в расчёте.
     *
     * @return array<string, mixed>
     */
    public function overpaymentProjectDetail(
        int $companyId,
        int $userId,
        int $projectId,
        ?string $monthYyyyMm,
        Carbon $nowUtc,
    ): array {
        $cp = Counterparty::query()
            ->where('company_id', $companyId)
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->firstOrFail();

        $isOwner = (string) $cp->company_role_code === CompanyRoleCode::OWNER->value;
        $scopeIds = $isOwner
            ? $this->participantIdsForCompany($companyId)
            : $this->participantIdsForCounterparty($companyId, (int) $cp->id);

        $project = Project::query()
            ->where('company_id', $companyId)
            ->whereKey($projectId)
            ->firstOrFail();

        $projectParticipantIds = ProjectParticipant::query()
            ->where('project_id', $projectId)
            ->whereIn('id', $scopeIds)
            ->where('is_active', true)
            ->pluck('id')
            ->map(fn ($id) => (int) $id)
            ->all();

        if ($projectParticipantIds === []) {
            abort(404);
        }

        $asOf = $this->analyticsAsOf($monthYyyyMm, $nowUtc);

        $earnedMap = $this->earnedCentsByParticipantBatch($companyId, $projectParticipantIds, $asOf);
        $recvMap = $this->receivedCentsByParticipantBatch($projectParticipantIds, $asOf);

        $overCentsSum = 0;
        foreach ($projectParticipantIds as $ppId) {
            $e = $earnedMap[$ppId] ?? 0;
            $r = $recvMap[$ppId] ?? 0;
            $overCentsSum += max($r - $e, 0);
        }

        if ($overCentsSum <= 0) {
            abort(404);
        }

        $earnedTotalCents = 0;
        $recvTotalCents = 0;
        foreach ($projectParticipantIds as $ppId) {
            $earnedTotalCents += $earnedMap[$ppId] ?? 0;
            $recvTotalCents += $recvMap[$ppId] ?? 0;
        }

        $transferRows = TransferOperation::query()
            ->from('transfer_operations')
            ->where('transfer_operations.project_id', $projectId)
            ->whereIn('transfer_operations.receiver_project_participant_id', $projectParticipantIds)
            ->where('transfer_operations.transfer_target_type', TransferTargetType::PERSONAL_BALANCE)
            ->whereNotNull('transfer_operations.wallets_applied_at')
            ->whereNull('transfer_operations.wallets_reverted_at')
            ->where('transfer_operations.wallets_applied_at', '<=', $asOf)
            ->orderBy('transfer_operations.wallets_applied_at')
            ->orderBy('transfer_operations.id')
            ->get([
                'transfer_operations.id',
                'transfer_operations.operation_number',
                'transfer_operations.amount',
                'transfer_operations.operation_status',
                'transfer_operations.wallets_applied_at',
                'transfer_operations.receiver_project_participant_id',
            ]);

        $transfers = [];
        foreach ($transferRows as $tr) {
            $amtCents = $this->moneyStringToCents((string) $tr->amount);
            $transfers[] = [
                'operation_kind'                  => 'transfer',
                'operation_id'                    => (int) $tr->id,
                'operation_number'                => $tr->operation_number !== null ? (string) $tr->operation_number : null,
                'project_id'                      => $projectId,
                'operation_date'                  => Carbon::parse($tr->wallets_applied_at)->format('Y-m-d'),
                'status'                          => $this->operationStatusToString($tr->operation_status),
                'metric_amount'                   => $this->formatMoney($amtCents / 100.0),
                'receiver_project_participant_id' => (int) $tr->receiver_project_participant_id,
            ];
        }

        $reportAgg = ReportWalletDelta::query()
            ->from('report_wallet_deltas')
            ->join('report_operations as ro', 'ro.id', '=', 'report_wallet_deltas.report_operation_id')
            ->whereNotNull('ro.wallets_applied_at')
            ->whereNull('ro.wallets_reverted_at')
            ->whereNull('report_wallet_deltas.reverted_at')
            ->where('report_wallet_deltas.field_name', 'personal_earned')
            ->where('ro.company_id', $companyId)
            ->where('ro.project_id', $projectId)
            ->where('report_wallet_deltas.applied_at', '<=', $asOf)
            ->whereIn('report_wallet_deltas.project_participant_id', $projectParticipantIds)
            ->groupBy('ro.id')
            ->orderByRaw('MIN(report_wallet_deltas.applied_at) asc')
            ->selectRaw('ro.id as report_id')
            ->selectRaw('MAX(ro.operation_number) as operation_number')
            ->selectRaw('MAX(ro.operation_date) as operation_date')
            ->selectRaw('MAX(ro.operation_status) as operation_status')
            ->selectRaw('SUM(report_wallet_deltas.delta_cents) as earned_cents')
            ->get();

        $reports = [];
        foreach ($reportAgg as $rw) {
            $ec = (int) $rw->earned_cents;
            if ($ec === 0) {
                continue;
            }
            $reports[] = [
                'operation_kind'   => 'report',
                'operation_id'     => (int) $rw->report_id,
                'operation_number' => $rw->operation_number !== null ? (string) $rw->operation_number : null,
                'project_id'       => $projectId,
                'operation_date'   => Carbon::parse($rw->operation_date)->format('Y-m-d'),
                'status'           => $this->operationStatusToString($rw->operation_status),
                'earned_amount'    => $this->formatMoney($ec / 100.0),
                'metric_amount'    => $this->formatMoney($ec / 100.0),
            ];
        }

        return [
            'project_id'         => $projectId,
            'project_name'       => (string) $project->name,
            'earned_amount'      => $this->formatMoney($earnedTotalCents / 100.0),
            'received_amount'    => $this->formatMoney($recvTotalCents / 100.0),
            'overpayment_amount' => $this->formatMoney($overCentsSum / 100.0),
            'transfers'          => $transfers,
            'reports'            => $reports,
        ];
    }

    private function analyticsAsOf(?string $monthYyyyMm, Carbon $nowUtc): Carbon
    {
        if ($monthYyyyMm === null || $monthYyyyMm === '') {
            return $nowUtc->copy();
        }

        $monthStart = Carbon::createFromFormat('Y-m', $monthYyyyMm, 'UTC')->startOfMonth();
        $monthEnd = (clone $monthStart)->endOfMonth();
        if ($monthEnd->gt($nowUtc)) {
            return $nowUtc->copy();
        }

        return $monthEnd;
    }

    /**
     * @return array{start: Carbon, months: list<Carbon>}
     */
    private function quarterBounds(Carbon $nowUtc): array
    {
        $startMonth = (int) (floor(($nowUtc->month - 1) / 3) * 3 + 1);
        $start = Carbon::create($nowUtc->year, $startMonth, 1, 0, 0, 0, 'UTC');
        $months = [$start->copy(), $start->copy()->addMonth(), $start->copy()->addMonths(2)];

        return ['start' => $start, 'months' => $months];
    }

    /** @return list<int> */
    private function participantIdsForCompany(int $companyId): array
    {
        return ProjectParticipant::query()
            ->whereIn('project_id', Project::query()->where('company_id', $companyId)->pluck('id'))
            ->where('is_active', true)
            ->pluck('id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }

    /** @return list<int> */
    private function participantIdsForCounterparty(int $companyId, int $counterpartyId): array
    {
        return ProjectParticipant::query()
            ->whereIn('project_id', Project::query()->where('company_id', $companyId)->pluck('id'))
            ->where('counterparty_id', $counterpartyId)
            ->where('is_active', true)
            ->pluck('id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }

    /**
     * Начислено personal_earned по участнику (накопительно до $asOf), батч по списку участников.
     *
     * @param  list<int>  $participantIds
     * @return array<int, int> project_participant_id => cents
     */
    private function earnedCentsByParticipantBatch(int $companyId, array $participantIds, Carbon $asOf): array
    {
        if ($participantIds === []) {
            return [];
        }

        $rows = ReportWalletDelta::query()
            ->from('report_wallet_deltas')
            ->join('report_operations as ro', 'ro.id', '=', 'report_wallet_deltas.report_operation_id')
            ->whereNotNull('ro.wallets_applied_at')
            ->whereNull('ro.wallets_reverted_at')
            ->whereNull('report_wallet_deltas.reverted_at')
            ->where('report_wallet_deltas.field_name', 'personal_earned')
            ->where('ro.company_id', $companyId)
            ->where('report_wallet_deltas.applied_at', '<=', $asOf)
            ->whereIn('report_wallet_deltas.project_participant_id', $participantIds)
            ->groupBy('report_wallet_deltas.project_participant_id')
            ->selectRaw('report_wallet_deltas.project_participant_id as pp_id')
            ->selectRaw('SUM(report_wallet_deltas.delta_cents) as cents')
            ->get();

        $out = [];
        foreach ($rows as $row) {
            $out[(int) $row->pp_id] = (int) $row->cents;
        }

        return $out;
    }

    /**
     * Получено на личный баланс по участнику (накопительно до $asOf).
     *
     * @param  list<int>  $participantIds
     * @return array<int, int> project_participant_id => cents
     */
    private function receivedCentsByParticipantBatch(array $participantIds, Carbon $asOf): array
    {
        if ($participantIds === []) {
            return [];
        }

        $rows = TransferOperation::query()
            ->where('transfer_target_type', TransferTargetType::PERSONAL_BALANCE)
            ->whereNotNull('wallets_applied_at')
            ->whereNull('wallets_reverted_at')
            ->where('wallets_applied_at', '<=', $asOf)
            ->whereIn('receiver_project_participant_id', $participantIds)
            ->groupBy('receiver_project_participant_id')
            ->selectRaw('receiver_project_participant_id as pp_id')
            ->selectRaw('SUM(CAST(amount AS DECIMAL(18,2))) as amt')
            ->get();

        $out = [];
        foreach ($rows as $row) {
            $out[(int) $row->pp_id] = (int) round(((float) $row->amt) * 100.0);
        }

        return $out;
    }

    /**
     * @param  list<int>  $participantIds
     * @return array{debt: string, overpayment: string}
     */
    private function debtOverpaymentTotalsMoney(int $companyId, array $participantIds, Carbon $asOf): array
    {
        if ($participantIds === []) {
            return [
                'debt'          => $this->formatMoney(0.0),
                'overpayment'   => $this->formatMoney(0.0),
            ];
        }

        $earned = $this->earnedCentsByParticipantBatch($companyId, $participantIds, $asOf);
        $recv = $this->receivedCentsByParticipantBatch($participantIds, $asOf);
        $debtCents = 0;
        $overCents = 0;
        foreach (array_unique(array_merge(array_keys($earned), array_keys($recv))) as $ppId) {
            $e = $earned[$ppId] ?? 0;
            $r = $recv[$ppId] ?? 0;
            $debtCents += max($e - $r, 0);
            $overCents += max($r - $e, 0);
        }

        return [
            'debt'        => $this->formatMoney($debtCents / 100.0),
            'overpayment' => $this->formatMoney($overCents / 100.0),
        ];
    }

    private function ownerIncomeFlowInRange(int $companyId, Carbon $start, Carbon $end): float
    {
        $cents = (int) ReportWalletDelta::query()
            ->join('report_operations as ro', 'ro.id', '=', 'report_wallet_deltas.report_operation_id')
            ->whereNotNull('ro.wallets_applied_at')
            ->whereNull('ro.wallets_reverted_at')
            ->whereNull('report_wallet_deltas.reverted_at')
            ->where('report_wallet_deltas.field_name', 'personal_earned')
            ->where('ro.company_id', $companyId)
            ->whereBetween('report_wallet_deltas.applied_at', [$start, $end])
            ->sum('report_wallet_deltas.delta_cents');

        return $cents / 100.0;
    }

    /**
     * @param  list<int>  $receiverParticipantIds
     */
    private function partnerIncomeTransferFlowInRange(array $receiverParticipantIds, Carbon $start, Carbon $end): float
    {
        if ($receiverParticipantIds === []) {
            return 0.0;
        }

        $sum = (string) (TransferOperation::query()
            ->where('transfer_target_type', TransferTargetType::PERSONAL_BALANCE)
            ->whereNotNull('wallets_applied_at')
            ->whereNull('wallets_reverted_at')
            ->whereBetween('wallets_applied_at', [$start, $end])
            ->whereIn('receiver_project_participant_id', $receiverParticipantIds)
            ->sum(DB::raw('CAST(amount AS DECIMAL(18,2))')) ?? '0');

        return (float) $sum;
    }

    private function countActiveProjectsOwner(int $companyId, Carbon $asOf): int
    {
        return Project::query()
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->where('created_at', '<=', $asOf)
            ->count();
    }

    private function countActiveProjectsPartnerHead(int $companyId, int $counterpartyId, Carbon $asOf): int
    {
        return Project::query()
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->where('created_at', '<=', $asOf)
            ->whereHas('participants', function ($q) use ($counterpartyId): void {
                $q->where('counterparty_id', $counterpartyId)
                    ->where('project_role_code', ProjectRoleCode::PROJECT_HEAD->value)
                    ->whereRaw('lower(level) = ?', ['first'])
                    ->where('is_active', true);
            })
            ->count();
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function buildOwnerIncomeOperationCards(int $companyId, Carbon $rangeStart, Carbon $rangeEnd): array
    {
        $sums = ReportWalletDelta::query()
            ->from('report_wallet_deltas')
            ->join('report_operations as ro', 'ro.id', '=', 'report_wallet_deltas.report_operation_id')
            ->join('projects as p', 'p.id', '=', 'ro.project_id')
            ->whereNotNull('ro.wallets_applied_at')
            ->whereNull('ro.wallets_reverted_at')
            ->whereNull('report_wallet_deltas.reverted_at')
            ->where('report_wallet_deltas.field_name', 'personal_earned')
            ->where('ro.company_id', $companyId)
            ->whereBetween('report_wallet_deltas.applied_at', [$rangeStart, $rangeEnd])
            ->groupBy('ro.id')
            ->orderByDesc('ro.id')
            ->limit(100)
            ->selectRaw('ro.id as report_id')
            ->selectRaw('MAX(ro.project_id) as project_id')
            ->selectRaw('MAX(ro.operation_number) as operation_number')
            ->selectRaw('MAX(ro.operation_date) as operation_date')
            ->selectRaw('MAX(ro.operation_status) as operation_status')
            ->selectRaw('MAX(p.name) as project_name')
            ->selectRaw('SUM(report_wallet_deltas.delta_cents) as metric_cents')
            ->get();

        $out = [];
        foreach ($sums as $row) {
            $cents = (int) $row->metric_cents;
            if ($cents === 0) {
                continue;
            }
            $id = (int) $row->report_id;
            $out[] = $this->shapeReportIncomeCard(
                reportId: $id,
                projectId: (int) $row->project_id,
                projectName: (string) $row->project_name,
                operationNumber: $row->operation_number !== null ? (string) $row->operation_number : null,
                operationDate: Carbon::parse($row->operation_date)->format('Y-m-d'),
                status: $this->operationStatusToString($row->operation_status),
                metricCents: $cents,
            );
        }

        return $out;
    }

    /**
     * @param  list<int>  $receiverParticipantIds
     * @return list<array<string, mixed>>
     */
    private function buildPartnerIncomeOperationCards(array $receiverParticipantIds, Carbon $rangeStart, Carbon $rangeEnd): array
    {
        if ($receiverParticipantIds === []) {
            return [];
        }

        $rows = TransferOperation::query()
            ->from('transfer_operations')
            ->join('projects as p', 'p.id', '=', 'transfer_operations.project_id')
            ->where('transfer_operations.transfer_target_type', TransferTargetType::PERSONAL_BALANCE)
            ->whereNotNull('transfer_operations.wallets_applied_at')
            ->whereNull('transfer_operations.wallets_reverted_at')
            ->whereBetween('transfer_operations.wallets_applied_at', [$rangeStart, $rangeEnd])
            ->whereIn('transfer_operations.receiver_project_participant_id', $receiverParticipantIds)
            ->orderByDesc('transfer_operations.id')
            ->limit(100)
            ->select([
                'transfer_operations.id',
                'transfer_operations.project_id',
                'transfer_operations.operation_number',
                'transfer_operations.amount',
                'transfer_operations.operation_status',
                'transfer_operations.wallets_applied_at',
                'p.name as project_name',
            ])
            ->get();

        $out = [];
        foreach ($rows as $row) {
            $cents = $this->moneyStringToCents((string) $row->amount);
            $out[] = $this->shapeTransferIncomeCard(
                transferId: (int) $row->id,
                projectId: (int) $row->project_id,
                projectName: (string) $row->project_name,
                operationNumber: $row->operation_number !== null ? (string) $row->operation_number : null,
                operationDate: Carbon::parse($row->wallets_applied_at)->format('Y-m-d'),
                status: $this->operationStatusToString($row->operation_status),
                metricCents: $cents,
            );
        }

        return $out;
    }

    /**
     * FIFO по каждому project_participant_id: переводы закрывают самые старые отчёты этого участника.
     *
     * @param  list<int>  $participantIds
     * @return list<array<string, mixed>>
     */
    private function buildDebtReportOperationCards(int $companyId, array $participantIds, Carbon $asOf): array
    {
        if ($participantIds === []) {
            return [];
        }

        $rows = ReportWalletDelta::query()
            ->from('report_wallet_deltas')
            ->join('report_operations as ro', 'ro.id', '=', 'report_wallet_deltas.report_operation_id')
            ->join('projects as p', 'p.id', '=', 'ro.project_id')
            ->whereNotNull('ro.wallets_applied_at')
            ->whereNull('ro.wallets_reverted_at')
            ->whereNull('report_wallet_deltas.reverted_at')
            ->where('report_wallet_deltas.field_name', 'personal_earned')
            ->where('ro.company_id', $companyId)
            ->where('report_wallet_deltas.applied_at', '<=', $asOf)
            ->whereIn('report_wallet_deltas.project_participant_id', $participantIds)
            ->groupBy('ro.id', 'report_wallet_deltas.project_participant_id')
            ->selectRaw('ro.id as report_id')
            ->selectRaw('report_wallet_deltas.project_participant_id as pp_id')
            ->selectRaw('MAX(ro.project_id) as project_id')
            ->selectRaw('MAX(ro.operation_number) as operation_number')
            ->selectRaw('MAX(ro.operation_date) as operation_date')
            ->selectRaw('MAX(ro.operation_status) as operation_status')
            ->selectRaw('MAX(p.name) as project_name')
            ->selectRaw('MIN(report_wallet_deltas.applied_at) as first_applied')
            ->selectRaw('SUM(report_wallet_deltas.delta_cents) as earned_cents')
            ->get();

        if ($rows->isEmpty()) {
            return [];
        }

        $byPp = [];
        foreach ($rows as $row) {
            $ppId = (int) $row->pp_id;
            $byPp[$ppId][] = $row;
        }
        foreach ($byPp as $ppId => $list) {
            usort($list, static function ($a, $b): int {
                return strcmp((string) $a->first_applied, (string) $b->first_applied);
            });
            $byPp[$ppId] = $list;
        }

        $recvMap = $this->receivedCentsByParticipantBatch($participantIds, $asOf);
        $cards = [];
        foreach ($byPp as $ppId => $reportRows) {
            $pool = $recvMap[$ppId] ?? 0;
            foreach ($reportRows as $row) {
                $earned = (int) $row->earned_cents;
                $allocated = min($earned, max(0, $pool));
                $pool -= $allocated;
                $debt = $earned - $allocated;
                if ($debt <= 0) {
                    continue;
                }
                $fifoHint = $allocated > 0;
                $cards[] = $this->shapeReportDebtCard(
                    reportId: (int) $row->report_id,
                    projectId: (int) $row->project_id,
                    projectName: (string) $row->project_name,
                    operationNumber: $row->operation_number !== null ? (string) $row->operation_number : null,
                    operationDate: Carbon::parse($row->operation_date)->format('Y-m-d'),
                    status: $this->operationStatusToString($row->operation_status),
                    accruedCents: $earned,
                    receivedCents: $allocated,
                    debtCents: $debt,
                    fifoAnalyticClosure: $fifoHint,
                );
            }
        }

        usort($cards, static function (array $a, array $b): int {
            return ((int) ($b['metric_amount_cents'] ?? 0)) <=> ((int) ($a['metric_amount_cents'] ?? 0));
        });

        return array_slice($cards, 0, 100);
    }

    /**
     * Агрегированная переплата по проекту (сумма положительных max(received−earned) по участникам проекта).
     *
     * @param  list<int>  $participantIds
     * @return list<array<string, mixed>>
     */
    private function buildOverpaymentAggregateOperationCards(int $companyId, array $participantIds, Carbon $asOf): array
    {
        if ($participantIds === []) {
            return [];
        }

        $earnedMap = $this->earnedCentsByParticipantBatch($companyId, $participantIds, $asOf);
        $recvMap = $this->receivedCentsByParticipantBatch($participantIds, $asOf);
        $ppToProject = ProjectParticipant::query()
            ->whereIn('id', $participantIds)
            ->pluck('project_id', 'id');

        $byProject = [];
        foreach (array_unique(array_merge(array_keys($earnedMap), array_keys($recvMap))) as $ppId) {
            $e = $earnedMap[$ppId] ?? 0;
            $r = $recvMap[$ppId] ?? 0;
            $over = max($r - $e, 0);
            if ($over <= 0) {
                continue;
            }
            $pid = (int) ($ppToProject[$ppId] ?? 0);
            if ($pid === 0) {
                continue;
            }
            if (! isset($byProject[$pid])) {
                $byProject[$pid] = [
                    'project_id'   => $pid,
                    'project_name' => '',
                    'earned'       => 0,
                    'received'     => 0,
                    'over'         => 0,
                ];
            }
            $byProject[$pid]['earned'] += $e;
            $byProject[$pid]['received'] += $r;
            $byProject[$pid]['over'] += $over;
        }

        foreach (array_keys($byProject) as $pid) {
            $name = Project::query()->whereKey($pid)->value('name');
            $byProject[$pid]['project_name'] = $name !== null ? (string) $name : '';
        }

        $cards = [];
        foreach ($byProject as $pid => $row) {
            if ($row['over'] <= 0) {
                continue;
            }
            $cards[] = $this->shapeAggregateOverpaymentCard(
                projectId: $pid,
                projectName: $row['project_name'] !== '' ? $row['project_name'] : '—',
                earnedCents: (int) $row['earned'],
                receivedCents: (int) $row['received'],
                overpaymentCents: (int) $row['over'],
            );
        }

        usort($cards, static function (array $a, array $b): int {
            return ((int) ($b['metric_amount_cents'] ?? 0)) <=> ((int) ($a['metric_amount_cents'] ?? 0));
        });

        return array_slice($cards, 0, 100);
    }

    /**
     * @return array<string, mixed>
     */
    private function shapeReportIncomeCard(
        int $reportId,
        int $projectId,
        string $projectName,
        ?string $operationNumber,
        string $operationDate,
        string $status,
        int $metricCents,
    ): array {
        $metric = $this->formatMoney($metricCents / 100.0);
        $code = $this->normalizeReportNumber($operationNumber, $reportId);

        return [
            'metric'               => 'income',
            'operation_kind'       => 'report',
            'operation_id'         => $reportId,
            'operation_number'     => $operationNumber,
            'project_id'           => $projectId,
            'project_name'         => $projectName,
            'operation_date'       => $operationDate,
            'status'               => $status,
            'amount'               => $metric,
            'metric_amount'        => $metric,
            'metric_amount_cents'  => $metricCents,
            'title'                => $projectName,
            'subtitle'             => $code,
            'earned_amount'        => $metric,
            'received_amount'      => null,
            'debt_amount'          => null,
            'overpayment_amount'   => null,
            'income_amount'        => $metric,
            'fifo_analytic_closure'=> false,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function shapeTransferIncomeCard(
        int $transferId,
        int $projectId,
        string $projectName,
        ?string $operationNumber,
        string $operationDate,
        string $status,
        int $metricCents,
    ): array {
        $metric = $this->formatMoney($metricCents / 100.0);
        $code = $this->normalizeTransferNumber($operationNumber, $transferId);

        return [
            'metric'               => 'income',
            'operation_kind'       => 'transfer',
            'operation_id'         => $transferId,
            'operation_number'     => $operationNumber,
            'project_id'           => $projectId,
            'project_name'         => $projectName,
            'operation_date'       => $operationDate,
            'status'               => $status,
            'amount'               => $metric,
            'metric_amount'        => $metric,
            'metric_amount_cents'  => $metricCents,
            'title'                => $projectName,
            'subtitle'             => $code,
            'earned_amount'        => null,
            'received_amount'      => $metric,
            'debt_amount'          => null,
            'overpayment_amount'   => null,
            'income_amount'        => $metric,
            'fifo_analytic_closure'=> false,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function shapeReportDebtCard(
        int $reportId,
        int $projectId,
        string $projectName,
        ?string $operationNumber,
        string $operationDate,
        string $status,
        int $accruedCents,
        int $receivedCents,
        int $debtCents,
        bool $fifoAnalyticClosure = false,
    ): array {
        $debtStr = $this->formatMoney($debtCents / 100.0);

        return [
            'metric'               => 'debt',
            'operation_kind'       => 'report',
            'operation_id'         => $reportId,
            'operation_number'     => $operationNumber,
            'project_id'           => $projectId,
            'project_name'         => $projectName,
            'operation_date'       => $operationDate,
            'status'               => $status,
            'amount'               => $debtStr,
            'metric_amount'        => $debtStr,
            'metric_amount_cents'  => $debtCents,
            'title'                => $projectName,
            'subtitle'             => $this->normalizeReportNumber($operationNumber, $reportId),
            'earned_amount'        => $this->formatMoney($accruedCents / 100.0),
            'received_amount'      => $this->formatMoney($receivedCents / 100.0),
            'debt_amount'          => $debtStr,
            'overpayment_amount'   => null,
            'income_amount'        => null,
            'fifo_analytic_closure'=> $fifoAnalyticClosure,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function shapeAggregateOverpaymentCard(
        int $projectId,
        string $projectName,
        int $earnedCents,
        int $receivedCents,
        int $overpaymentCents,
    ): array {
        $overStr = $this->formatMoney($overpaymentCents / 100.0);

        return [
            'metric'               => 'overpayment',
            'operation_kind'       => 'aggregate',
            'operation_id'         => null,
            'operation_number'     => null,
            'project_id'           => $projectId,
            'project_name'         => $projectName,
            'operation_date'       => null,
            'status'               => null,
            'amount'               => $overStr,
            'metric_amount'        => $overStr,
            'metric_amount_cents'  => $overpaymentCents,
            'title'                => 'aggregate_project_overpayment',
            'subtitle'             => $projectName,
            'earned_amount'        => $this->formatMoney($earnedCents / 100.0),
            'received_amount'      => $this->formatMoney($receivedCents / 100.0),
            'debt_amount'          => null,
            'overpayment_amount'   => $overStr,
            'income_amount'        => null,
            'fifo_analytic_closure'=> false,
        ];
    }

    private function normalizeReportNumber(?string $operationNumber, int $reportId): string
    {
        if ($operationNumber !== null && $operationNumber !== '') {
            return $operationNumber;
        }

        return 'REP-'.$reportId;
    }

    private function normalizeTransferNumber(?string $operationNumber, int $transferId): string
    {
        if ($operationNumber !== null && $operationNumber !== '') {
            return $operationNumber;
        }

        return 'TRF-'.$transferId;
    }

    private function operationStatusToString(mixed $status): string
    {
        if ($status instanceof \BackedEnum) {
            return (string) $status->value;
        }

        return (string) $status;
    }

    private function moneyStringToCents(string $amount): int
    {
        return (int) round(((float) str_replace(',', '.', trim($amount))) * 100.0);
    }

    private function formatMoney(float $value): string
    {
        return number_format($value, 2, '.', '');
    }

    /**
     * @return array{month: string, active_projects: int, income_total: string, debt_total: string, overpayment_total: string}
     */
    private function monthSliceOwner(
        int $companyId,
        array $participantIdsCompany,
        Carbon $mStart,
        Carbon $nowUtc,
    ): array {
        if ($mStart->gt($nowUtc)) {
            return $this->emptyMonthRow($mStart);
        }

        $mEnd = (clone $mStart)->endOfMonth();
        if ($mEnd->gt($nowUtc)) {
            $mEnd = $nowUtc->copy();
        }
        $flowStart = $mStart->copy();
        $flowEnd = $mEnd->copy();

        $tot = $this->debtOverpaymentTotalsMoney($companyId, $participantIdsCompany, $mEnd);

        return [
            'month'             => $mStart->format('Y-m'),
            'active_projects'   => $this->countActiveProjectsOwner($companyId, $mEnd),
            'income_total'      => $this->formatMoney($this->ownerIncomeFlowInRange($companyId, $flowStart, $flowEnd)),
            'debt_total'        => $tot['debt'],
            'overpayment_total' => $tot['overpayment'],
        ];
    }

    /**
     * @return array{month: string, active_projects: int, income_total: string, debt_total: string, overpayment_total: string}
     */
    private function monthSlicePartner(
        int $companyId,
        int $counterpartyId,
        array $participantIdsUser,
        Carbon $mStart,
        Carbon $nowUtc,
    ): array {
        if ($mStart->gt($nowUtc)) {
            return $this->emptyMonthRow($mStart);
        }

        $mEnd = (clone $mStart)->endOfMonth();
        if ($mEnd->gt($nowUtc)) {
            $mEnd = $nowUtc->copy();
        }
        $flowStart = $mStart->copy();
        $flowEnd = $mEnd->copy();

        $tot = $this->debtOverpaymentTotalsMoney($companyId, $participantIdsUser, $mEnd);

        return [
            'month'             => $mStart->format('Y-m'),
            'active_projects'   => $this->countActiveProjectsPartnerHead($companyId, $counterpartyId, $mEnd),
            'income_total'      => $this->formatMoney($this->partnerIncomeTransferFlowInRange($participantIdsUser, $flowStart, $flowEnd)),
            'debt_total'        => $tot['debt'],
            'overpayment_total' => $tot['overpayment'],
        ];
    }

    /**
     * @return array{month: string, active_projects: int, income_total: string, debt_total: string, overpayment_total: string}
     */
    private function emptyMonthRow(Carbon $mStart): array
    {
        return [
            'month'             => $mStart->format('Y-m'),
            'active_projects'   => 0,
            'income_total'      => $this->formatMoney(0.0),
            'debt_total'        => $this->formatMoney(0.0),
            'overpayment_total' => $this->formatMoney(0.0),
        ];
    }
}
