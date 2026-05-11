<?php

namespace App\Modules\Projects\Services;

use App\Models\User;
use App\Modules\Projects\Models\Project;
use Illuminate\Support\Facades\Log;

/**
 * ТЗ-07: внутренний блок «Данные по проекту».
 */
final class ProjectInternalMetricsService
{
    public function __construct(
        private readonly ProjectSummaryMetricsService $metrics,
        private readonly ProjectSummaryVisibilityService $visibility,
    ) {}

    /**
     * @throws \Symfony\Component\HttpKernel\Exception\HttpException
     */
    public function assertCanView(User $user, Project $project, ?int $companyId): void
    {
        if ($companyId !== null) {
            $flags = $this->visibility->flagsForCompanyWorkspace($user, $companyId, $project);
            if (! $flags['can_view_internal_metrics']) {
                Log::warning('project_internal_metrics.forbidden', [
                    'workspace' => 'company',
                    'user_id' => $user->getKey(),
                    'company_id' => $companyId,
                    'project_id' => $project->getKey(),
                ]);
                abort(403, 'Forbidden.');
            }

            return;
        }

        $flags = $this->visibility->flagsForPersonalWorkspace($user, $project);
        if (! $flags['can_view_internal_metrics']) {
            Log::warning('project_internal_metrics.forbidden', [
                'workspace' => 'personal',
                'user_id' => $user->getKey(),
                'project_id' => $project->getKey(),
            ]);
            abort(403, 'Forbidden.');
        }
    }

    /**
     * @return array{
     *   metrics: array{
     *     participants_accountable_balance: string,
     *     project_debt_to_counterparties: string,
     *     overpayment_or_missing_reports: string,
     *     project_balance: string
     *   }
     * }
     */
    public function buildPayload(Project $project): array
    {
        return [
            'metrics' => [
                'participants_accountable_balance' => $this->metrics->participantsAccountableBalanceExcludingCustomer($project),
                'project_debt_to_counterparties'   => $this->metrics->zeroPlaceholder(),
                'overpayment_or_missing_reports'   => $this->metrics->zeroPlaceholder(),
                'project_balance'                  => $this->metrics->customerAccountableBalance($project),
            ],
        ];
    }
}
