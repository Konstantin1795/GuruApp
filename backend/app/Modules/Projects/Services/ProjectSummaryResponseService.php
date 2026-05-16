<?php

namespace App\Modules\Projects\Services;

use App\Models\User;
use App\Modules\Projects\Models\Project;

/**
 * Сборка ответа GET projects/{id}/summary для company / personal workspace.
 */
final class ProjectSummaryResponseService
{
    public function __construct(
        private readonly ProjectSummaryMetricsService $metrics,
        private readonly ProjectSummaryVisibilityService $visibility,
        private readonly ProjectExpenseItemAccessService $expenseItemAccess,
        private readonly PriceListAccessService $priceListAccess,
    ) {}

    /**
     * @return array{
     *   project: array<string, mixed>,
     *   metrics: array{income_total: string, expense_total: string, project_balance: string},
     *   visibility: array<string, bool>
     * }
     *
     * В `metrics`: `expense_total` — сумма `customer_total_amount` по REPORT с применёнными и не откатанными дельтами;
     * `project_balance` — поступление минус этот расход (карточка «Показатели проекта»).
     */
    public function build(User $user, Project $project, ?int $companyId): array
    {
        $project->loadMissing('company');

        $visibility = $companyId !== null
            ? $this->visibility->flagsForCompanyWorkspace($user, $companyId, $project)
            : $this->visibility->flagsForPersonalWorkspace($user, $project);

        $visibility = array_merge(
            $visibility,
            $companyId !== null
                ? $this->expenseItemAccess->visibilityFlagsForSummary($user, $companyId, $project)
                : [
                    'can_view_expense_items' => false,
                    'can_manage_expense_items' => false,
                ],
        );

        $visibility = array_merge(
            $visibility,
            $companyId !== null
                ? $this->priceListAccess->projectSummaryFlags($user, $companyId, $project)
                : [
                    'can_view_project_price_lists' => false,
                    'can_manage_project_price_list_attachments' => false,
                ],
        );

        return [
            'project' => [
                'id'               => $project->id,
                'name'             => $project->name,
                'company_id'       => $project->company_id,
                'company_name'     => $project->company?->name ?? '',
                'address'          => null,
                'delivery_date'    => null,
                'progress_percent' => (int) $project->progress_percent,
                'is_active'        => (bool) $project->is_active,
            ],
            'metrics' => [
                'income_total'    => $this->metrics->incomeTotalApplied($project),
                'expense_total'   => $this->metrics->reportExpenseTotalApplied($project),
                'project_balance' => $this->metrics->summaryProjectBalanceIncomeMinusExpense($project),
            ],
            'visibility' => $visibility,
        ];
    }
}
