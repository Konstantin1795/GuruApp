<?php

namespace App\Modules\Operations\Services;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Models\TransferOperation;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Database\Eloquent\Builder;

/**
 * Правила видимости TRANSFER по проекту и в агрегированных выборках.
 *
 * Базово: пользователь видит операцию, только если его {@see ProjectParticipant} участвует
 * в строке перевода (инициатор / отправитель / получатель). Роль PROJECT_HEAD — все операции
 * **своего** проекта. Для ленты «все операции» без расширения РП на весь проект используйте
 * {@see self::transferQueryParticipationOnlyForUser} / {@see self::transferQueryParticipationOnlyAcrossProjects}.
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

    /**
     * Все переводы по нескольким проектам с теми же правилами видимости, что и внутри проекта.
     *
     * @param iterable<int, Project> $projects
     */
    public function transferQueryForUserAcrossProjects(iterable $projects, int $userId): Builder
    {
        $projects = is_array($projects) ? $projects : iterator_to_array($projects);
        if ($projects === []) {
            return TransferOperation::query()->whereRaw('1 = 0');
        }

        return TransferOperation::query()->where(function (Builder $outer) use ($projects, $userId): void {
            foreach ($projects as $project) {
                $outer->orWhere(function (Builder $q) use ($project, $userId): void {
                    $sub = $this->transferQueryForUser($project, $userId);
                    $q->whereIn('transfer_operations.id', $sub->select('transfer_operations.id'));
                });
            }
        });
    }

    /**
     * Агрегированная лента «все операции»: только переводы, где участник фигурирует в операции
     * (инициатор / отправитель / получатель), без правила «РП видит все проекта».
     */
    public function transferQueryParticipationOnlyForUser(Project $project, int $userId): Builder
    {
        $query = TransferOperation::query()->where('project_id', $project->id);
        $participant = $this->participantForUser($project, $userId);

        if (! $participant) {
            return $query->whereRaw('1 = 0');
        }

        $participantId = (int) $participant->id;

        return $query->where(function (Builder $q) use ($participantId): void {
            $q->where('initiator_project_participant_id', $participantId)
                ->orWhere('sender_project_participant_id', $participantId)
                ->orWhere('receiver_project_participant_id', $participantId);
        });
    }

    /**
     * @param iterable<int, Project> $projects
     */
    public function transferQueryParticipationOnlyAcrossProjects(iterable $projects, int $userId): Builder
    {
        $projects = is_array($projects) ? $projects : iterator_to_array($projects);
        if ($projects === []) {
            return TransferOperation::query()->whereRaw('1 = 0');
        }

        return TransferOperation::query()->where(function (Builder $outer) use ($projects, $userId): void {
            foreach ($projects as $project) {
                $outer->orWhere(function (Builder $q) use ($project, $userId): void {
                    $sub = $this->transferQueryParticipationOnlyForUser($project, $userId);
                    $q->whereIn('transfer_operations.id', $sub->select('transfer_operations.id'));
                });
            }
        });
    }

    public function participantForUser(Project $project, int $userId): ?ProjectParticipant
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
