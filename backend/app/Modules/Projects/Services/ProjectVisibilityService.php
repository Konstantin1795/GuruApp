<?php

namespace App\Modules\Projects\Services;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Models\Project;
use Illuminate\Database\Eloquent\Builder;

/**
 * Central project visibility rules.
 *
 * Access chain:
 * User -> Counterparty -> ProjectParticipant.
 *
 * Exceptions:
 * - Company OWNER sees all projects in the owned company;
 * - Company PARTNER sees only projects where their Counterparty is ProjectParticipant.
 */
final class ProjectVisibilityService
{
    public function queryForCompanyWorkspace(int $userId, int $companyId): Builder
    {
        $counterparty = $this->companyWorkspaceCounterparty($userId, $companyId);

        $query = Project::query()->where('company_id', $companyId);

        if (! $counterparty) {
            return $query->whereRaw('1 = 0');
        }

        if ($counterparty->company_role_code === CompanyRoleCode::OWNER->value) {
            return $query;
        }

        return $query->whereHas('participants', function (Builder $participantQuery) use ($counterparty): void {
            $participantQuery
                ->where('counterparty_id', (int) $counterparty->id)
                ->where('is_active', true);
        });
    }

    public function assertCanAccessCompanyProject(int $userId, int $companyId, int $projectId): Project
    {
        return $this->queryForCompanyWorkspace($userId, $companyId)
            ->whereKey($projectId)
            ->firstOrFail();
    }

    public function assertCanManageCompanyProject(int $userId, int $companyId, int $projectId): Project
    {
        $project = Project::query()
            ->where('company_id', $companyId)
            ->whereKey($projectId)
            ->firstOrFail();

        $counterparty = $this->companyWorkspaceCounterparty($userId, $companyId);
        if (! $counterparty) {
            abort(403, 'Forbidden.');
        }

        if ($counterparty->company_role_code === CompanyRoleCode::OWNER->value) {
            return $project;
        }

        $isProjectHead = $project->participants()
            ->where('counterparty_id', (int) $counterparty->id)
            ->where('project_role_code', ProjectRoleCode::PROJECT_HEAD->value)
            ->where('is_active', true)
            ->exists();

        if (! $isProjectHead) {
            abort(403, 'Forbidden.');
        }

        return $project;
    }

    public function canSeeAllProjectOperations(int $userId, Project $project): bool
    {
        return $project->participants()
            ->where('project_role_code', ProjectRoleCode::PROJECT_HEAD->value)
            ->where('is_active', true)
            ->whereHas('counterparty', function (Builder $query) use ($userId): void {
                $query->where('user_id', $userId)->where('is_active', true);
            })
            ->exists();
    }

    /**
     * Personal workspace: пользователь видит проект, если есть его активный ProjectParticipant (любая роль).
     */
    public function assertCanAccessPersonalWorkspaceProject(int $userId, int $projectId): Project
    {
        $project = Project::query()->whereKey($projectId)->firstOrFail();

        $exists = $project->participants()
            ->where('is_active', true)
            ->whereHas('counterparty', function (Builder $query) use ($userId): void {
                $query->where('user_id', $userId)->where('is_active', true);
            })
            ->exists();

        if (! $exists) {
            abort(403, 'Forbidden.');
        }

        return $project;
    }

    private function companyWorkspaceCounterparty(int $userId, int $companyId): ?Counterparty
    {
        return Counterparty::query()
            ->where('company_id', $companyId)
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->whereIn('company_role_code', [
                CompanyRoleCode::OWNER->value,
                CompanyRoleCode::PARTNER->value,
            ])
            ->first();
    }
}
