<?php

namespace App\Modules\Operations\Services;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Models\TransferOperation;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Database\Eloquent\Builder;

/**
 * Central operation visibility rules.
 *
 * General rule: a user sees an operation only if their ProjectParticipant
 * participates in it. PROJECT_HEAD sees all operations of their project.
 */
final class OperationVisibilityService
{
    public function transferQueryForUser(Project $project, int $userId): Builder
    {
        $query = TransferOperation::query()->where('project_id', $project->id);
        $participant = $this->participantForUser($project, $userId);

        if (! $participant) {
            return $query->whereRaw('1 = 0');
        }

        if ($participant->project_role_code === ProjectRoleCode::PROJECT_HEAD->value) {
            return $query;
        }

        return $query->where(function (Builder $q) use ($participant): void {
            $participantId = (int) $participant->id;
            $q->where('initiator_project_participant_id', $participantId)
                ->orWhere('sender_project_participant_id', $participantId)
                ->orWhere('receiver_project_participant_id', $participantId);
        });
    }

    public function assertCanViewTransfer(Project $project, int $userId, int $transferId): TransferOperation
    {
        return $this->transferQueryForUser($project, $userId)
            ->whereKey($transferId)
            ->firstOrFail();
    }

    private function participantForUser(Project $project, int $userId): ?ProjectParticipant
    {
        return ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('is_active', true)
            ->whereHas('counterparty', function (Builder $query) use ($userId): void {
                $query->where('user_id', $userId)->where('is_active', true);
            })
            ->first();
    }
}
