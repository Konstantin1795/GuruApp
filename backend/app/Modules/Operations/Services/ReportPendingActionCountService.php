<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\ProjectVisibilityService;

final class ReportPendingActionCountService
{
    public function __construct(
        private readonly ProjectVisibilityService $projectVisibility,
        private readonly ReportVisibilityService $reportVisibility,
        private readonly ReportAvailableActionsService $availableActions,
    ) {}

    public function countForCompanyWorkspace(int $userId, int $companyId): int
    {
        $projects = $this->projectVisibility
            ->queryForCompanyWorkspace($userId, $companyId)
            ->get();

        return $this->countAcrossProjects($projects, $userId);
    }

    public function countForPersonalWorkspace(int $userId): int
    {
        $projectIds = ProjectParticipant::query()
            ->where('is_active', true)
            ->whereHas('counterparty', function ($q) use ($userId): void {
                $q->where('user_id', $userId)->where('is_active', true);
            })
            ->distinct()
            ->pluck('project_id');

        $projects = Project::query()->whereIn('id', $projectIds)->get();

        return $this->countAcrossProjects($projects, $userId);
    }

    /**
     * @param iterable<int, Project> $projects
     */
    private function countAcrossProjects(iterable $projects, int $userId): int
    {
        $count = 0;

        foreach ($projects as $project) {
            $participant = $this->reportVisibility->participantForUser($project, $userId);
            if (! $participant) {
                continue;
            }

            $q = $this->reportVisibility
                ->reportQueryForUser($project, $userId)
                ->with('initiator');

            foreach ($q->cursor() as $report) {
                if ($this->availableActions->hasPendingConfirmationAction($participant, $report)) {
                    $count++;
                }
            }
        }

        return $count;
    }
}
