<?php

namespace App\Modules\Operations\Services;

use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\ProjectVisibilityService;

/**
 * Счётчик «ожидают вашего шага» по TRANSFER для бейджа воркспейса.
 *
 * Должен оставаться согласован с {@see TransferAvailableActionsService::hasPendingConfirmationAction}
 * и с вкладкой `tab=pending` в {@see AggregatedOperationsHistoryService} — иначе расходится UX с лентой.
 */
final class TransferPendingActionCountService
{
    public function __construct(
        private readonly OperationVisibilityService $operationVisibility,
        private readonly TransferAvailableActionsService $availableActions,
        private readonly ProjectVisibilityService $projectVisibility,
    ) {}

    /**
     * Переводы, по которым у участника есть «входящее» ожидание подтверждения / повторной отправки
     * (см. TransferAvailableActionsService::hasPendingConfirmationAction), без опциональных кнопок.
     */
    public function countForCompanyWorkspace(int $userId, int $companyId): int
    {
        $projects = $this->projectVisibility
            ->queryForCompanyWorkspace($userId, $companyId)
            ->get();

        $count = 0;

        foreach ($projects as $project) {
            $participant = $this->operationVisibility->participantForUser($project, $userId);
            if (! $participant) {
                continue;
            }

            $query = $this->operationVisibility
                ->transferQueryForUser($project, $userId)
                ->with('initiator');

            foreach ($query->cursor() as $transfer) {
                if ($this->availableActions->hasPendingConfirmationAction($participant, $transfer)) {
                    $count++;
                }
            }
        }

        return $count;
    }

    /**
     * Personal-workspace: те же правила по всем проектам с участием пользователя.
     */
    public function countForPersonalWorkspace(int $userId): int
    {
        $projectIds = ProjectParticipant::query()
            ->where('is_active', true)
            ->whereHas('counterparty', function ($q) use ($userId): void {
                $q->where('user_id', $userId)->where('is_active', true);
            })
            ->distinct()
            ->pluck('project_id');

        $count = 0;

        foreach ($projectIds as $projectId) {
            $project = Project::query()->whereKey($projectId)->first();
            if (! $project) {
                continue;
            }

            $participant = $this->operationVisibility->participantForUser($project, $userId);
            if (! $participant) {
                continue;
            }

            $query = $this->operationVisibility
                ->transferQueryForUser($project, $userId)
                ->with('initiator');

            foreach ($query->cursor() as $transfer) {
                if ($this->availableActions->hasPendingConfirmationAction($participant, $transfer)) {
                    $count++;
                }
            }
        }

        return $count;
    }
}
