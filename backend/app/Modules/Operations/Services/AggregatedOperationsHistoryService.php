<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Modules\Operations\Http\Resources\IncomeOperationResource;
use App\Modules\Operations\Http\Resources\TransferOperationResource;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Models\TransferOperation;
use Illuminate\Support\Facades\DB;

/**
 * Объединённая история TRANSFER + INCOME для экрана «История операций» (ТЗ-06.1).
 */
final class AggregatedOperationsHistoryService
{
    public function __construct(
        private readonly OperationVisibilityService $operationVisibility,
        private readonly IncomeVisibilityService $incomeVisibility,
    ) {}

    /**
     * @param iterable<int, \App\Modules\Projects\Models\Project> $projects
     *
     * @return array{items: array<int, array<string, mixed>>, total: int}
     */
    public function paginate(iterable $projects, int $userId, int $perPage, int $page): array
    {
        $projects = is_array($projects) ? $projects : iterator_to_array($projects);
        if ($projects === []) {
            return ['items' => [], 'total' => 0];
        }

        $tq = $this->operationVisibility
            ->transferQueryForUserAcrossProjects($projects, $userId)
            ->select([
                DB::raw("'transfer' as operation_kind"),
                'transfer_operations.id as operation_row_id',
                DB::raw('GREATEST(transfer_operations.updated_at, transfer_operations.created_at) as operation_sort_at'),
                'transfer_operations.project_id',
            ]);

        $iq = $this->incomeVisibility
            ->incomeQueryForUserAcrossProjects($projects, $userId)
            ->select([
                DB::raw("'income' as operation_kind"),
                'income_operations.id as operation_row_id',
                DB::raw('GREATEST(income_operations.updated_at, income_operations.created_at) as operation_sort_at'),
                'income_operations.project_id',
            ]);

        $union = $tq->unionAll($iq);

        $total = (int) DB::query()->fromSub($union, 'merged')->count();

        $offset = max(0, ($page - 1) * $perPage);

        $rows = DB::query()
            ->fromSub($union, 'merged')
            ->orderByDesc('operation_sort_at')
            ->orderByDesc('operation_row_id')
            ->offset($offset)
            ->limit($perPage)
            ->get();

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
                        'project_id'     => (int) $t->project_id,
                        'transfer'       => (new TransferOperationResource($t))->resolve(),
                    ];
                }
            } else {
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
                        'project_id'     => (int) $i->project_id,
                        'income'         => (new IncomeOperationResource($i))->resolve(),
                    ];
                }
            }
        }

        return ['items' => $items, 'total' => $total];
    }
}
