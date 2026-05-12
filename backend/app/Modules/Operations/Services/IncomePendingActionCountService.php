<?php

namespace App\Modules\Operations\Services;

use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\ProjectVisibilityService;

/**
 * Счётчик «ожидают вашего шага» по INCOME для бейджа воркспейса.
 *
 * Логика отбора тех же операций, что и {@see IncomeAvailableActionsService::hasPendingConfirmationAction}
 * (см. {@see IncomeAvailableActionsService::PENDING_BADGE_KEYS}); менять только вместе с агрегированной историей.
 */
final class IncomePendingActionCountService
{
    public function __construct(
        private readonly IncomeVisibilityService $incomeVisibility,
        private readonly IncomeAvailableActionsService $availableActions,
        private readonly ProjectVisibilityService $projectVisibility,
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
            $participant = $this->incomeVisibility->participantForUser($project, $userId);
            if (! $participant) {
                continue;
            }

            $query = $this->incomeVisibility
                ->incomeQueryForUser($project, $userId)
                ->with('initiator');

            foreach ($query->cursor() as $income) {
                if ($this->availableActions->hasPendingConfirmationAction($participant, $income)) {
                    $count++;
                }
            }
        }

        return $count;
    }
}
