<?php

namespace App\Modules\Operations\Services;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Database\Eloquent\Builder;

/**
 * ТЗ-06: видимость поступлений по проекту (не смешивать с Transfer).
 */
final class IncomeVisibilityService
{
    public function incomeQueryForUser(Project $project, int $userId): Builder
    {
        $query = IncomeOperation::query()->where('project_id', $project->id);

        if ($this->userIsCompanyOwnerForProjectCompany($userId, $project)) {
            return $query;
        }

        $participant = $this->participantForUser($project, $userId);

        if (! $participant) {
            return $query->whereRaw('1 = 0');
        }

        $role = $participant->project_role_code;
        $levelFirst = strtolower((string) $participant->level) === 'first';

        if ($role === ProjectRoleCode::PROJECT_HEAD->value) {
            return $query;
        }

        if ($role === ProjectRoleCode::PARTNER->value && $levelFirst) {
            return $query;
        }

        if ($role === ProjectRoleCode::CUSTOMER->value) {
            return $query->where('customer_project_participant_id', (int) $participant->id);
        }

        $pid = (int) $participant->id;

        return $query->where(function (Builder $q) use ($pid): void {
            $q->where('initiator_project_participant_id', $pid)
                ->orWhere('project_head_project_participant_id', $pid)
                ->orWhere('customer_project_participant_id', $pid);
        });
    }

    public function assertCanViewIncome(Project $project, int $userId, int $incomeId): IncomeOperation
    {
        return $this->incomeQueryForUser($project, $userId)
            ->whereKey($incomeId)
            ->firstOrFail();
    }

    /**
     * @param iterable<int, Project> $projects
     */
    public function incomeQueryForUserAcrossProjects(iterable $projects, int $userId): Builder
    {
        $projects = is_array($projects) ? $projects : iterator_to_array($projects);
        if ($projects === []) {
            return IncomeOperation::query()->whereRaw('1 = 0');
        }

        return IncomeOperation::query()->where(function (Builder $outer) use ($projects, $userId): void {
            foreach ($projects as $project) {
                $outer->orWhere(function (Builder $q) use ($project, $userId): void {
                    $sub = $this->incomeQueryForUser($project, $userId);
                    $q->whereIn('income_operations.id', $sub->select('income_operations.id'));
                });
            }
        });
    }

    /**
     * Агрегированная лента «все операции»: только поступления, где участник — инициатор / РП / заказчик по строке операции.
     */
    public function incomeQueryParticipationOnlyForUser(Project $project, int $userId): Builder
    {
        $query = IncomeOperation::query()->where('project_id', $project->id);
        $participant = $this->participantForUser($project, $userId);

        if (! $participant) {
            return $query->whereRaw('1 = 0');
        }

        $pid = (int) $participant->id;

        return $query->where(function (Builder $q) use ($pid): void {
            $q->where('initiator_project_participant_id', $pid)
                ->orWhere('project_head_project_participant_id', $pid)
                ->orWhere('customer_project_participant_id', $pid);
        });
    }

    /**
     * @param iterable<int, Project> $projects
     */
    public function incomeQueryParticipationOnlyAcrossProjects(iterable $projects, int $userId): Builder
    {
        $projects = is_array($projects) ? $projects : iterator_to_array($projects);
        if ($projects === []) {
            return IncomeOperation::query()->whereRaw('1 = 0');
        }

        return IncomeOperation::query()->where(function (Builder $outer) use ($projects, $userId): void {
            foreach ($projects as $project) {
                $outer->orWhere(function (Builder $q) use ($project, $userId): void {
                    $sub = $this->incomeQueryParticipationOnlyForUser($project, $userId);
                    $q->whereIn('income_operations.id', $sub->select('income_operations.id'));
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

    /**
     * Владелец компании видит поступления по всем проектам компании (ТЗ-06.1), даже без строки участника в проекте.
     */
    private function userIsCompanyOwnerForProjectCompany(int $userId, Project $project): bool
    {
        return Counterparty::query()
            ->where('company_id', $project->company_id)
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->where('company_role_code', CompanyRoleCode::OWNER->value)
            ->exists();
    }
}
