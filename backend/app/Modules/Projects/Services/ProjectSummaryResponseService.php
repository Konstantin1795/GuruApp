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
    ) {}

    /**
     * @return array{
     *   project: array<string, mixed>,
     *   metrics: array{income_total: string, expense_total: string, project_balance: string},
     *   visibility: array<string, bool>
     * }
     */
    public function build(User $user, Project $project, ?int $companyId): array
    {
        $project->loadMissing('company');

        $visibility = $companyId !== null
            ? $this->visibility->flagsForCompanyWorkspace($user, $companyId, $project)
            : $this->visibility->flagsForPersonalWorkspace($user, $project);

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
                'expense_total'   => $this->metrics->expenseTotalPlaceholder(),
                'project_balance' => $this->metrics->customerAccountableBalance($project),
            ],
            'visibility' => $visibility,
        ];
    }
}
