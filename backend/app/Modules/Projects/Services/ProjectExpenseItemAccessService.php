<?php

namespace App\Modules\Projects\Services;

use App\Models\User;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Support\Collection;

/**
 * ТЗ-10A: доступ к статьям расходов проекта (company workspace).
 *
 * Матрица OWNER / PROJECT_HEAD (управление) vs PARTNER first-order (только просмотр) и
 * привязка к видимости проекта — здесь; не дублировать в контроллерах условиями «на глаз».
 */
final class ProjectExpenseItemAccessService
{
    public function __construct(
        private readonly ProjectVisibilityService $visibility,
    ) {}

    public function assertCanView(User $user, int $companyId, int $projectId): Project
    {
        $project = $this->visibility->assertCanAccessCompanyProject((int) $user->id, $companyId, $projectId);

        if ($this->hasExpenseItemsViewAccess((int) $user->id, $companyId, $project)) {
            return $project;
        }

        abort(403, 'Forbidden.');
    }

    public function canView(User $user, int $companyId, Project $project): bool
    {
        return $this->hasExpenseItemsViewAccess((int) $user->id, $companyId, $project);
    }

    public function assertCanManage(User $user, int $companyId, int $projectId): Project
    {
        $project = Project::query()
            ->where('company_id', $companyId)
            ->whereKey($projectId)
            ->firstOrFail();

        $counterparty = $this->companyWorkspaceCounterparty((int) $user->id, $companyId);
        if (! $counterparty) {
            abort(403, 'Forbidden.');
        }

        if ($counterparty->company_role_code === CompanyRoleCode::OWNER->value) {
            return $project;
        }

        $isFirstOrderHead = ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('counterparty_id', (int) $counterparty->id)
            ->where('project_role_code', ProjectRoleCode::PROJECT_HEAD->value)
            ->whereRaw('LOWER(level) = ?', ['first'])
            ->where('is_active', true)
            ->exists();

        if (! $isFirstOrderHead) {
            abort(403, 'Forbidden.');
        }

        return $project;
    }

    /**
     * Флаги для GET projects/{id}/summary (company workspace).
     *
     * @return array{can_view_expense_items: bool, can_manage_expense_items: bool}
     */
    public function visibilityFlagsForSummary(User $user, int $companyId, Project $project): array
    {
        $canView = $this->hasExpenseItemsViewAccess((int) $user->id, $companyId, $project);
        $canManage = $this->canManageWithoutAbort($user, $companyId, $project);

        return [
            'can_view_expense_items'   => $canView,
            'can_manage_expense_items' => $canManage,
        ];
    }

    private function canManageWithoutAbort(User $user, int $companyId, Project $project): bool
    {
        $counterparty = $this->companyWorkspaceCounterparty((int) $user->id, $companyId);
        if (! $counterparty) {
            return false;
        }

        if ($counterparty->company_role_code === CompanyRoleCode::OWNER->value) {
            return (int) $project->company_id === $companyId;
        }

        return ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('counterparty_id', (int) $counterparty->id)
            ->where('project_role_code', ProjectRoleCode::PROJECT_HEAD->value)
            ->whereRaw('LOWER(level) = ?', ['first'])
            ->where('is_active', true)
            ->exists();
    }

    private function hasExpenseItemsViewAccess(int $userId, int $companyId, Project $project): bool
    {
        $counterparty = $this->companyWorkspaceCounterparty($userId, $companyId);
        if (! $counterparty) {
            return false;
        }

        if ($counterparty->company_role_code === CompanyRoleCode::OWNER->value) {
            return true;
        }

        return $this->participantsForUserOnProject($userId, $project)
            ->contains(fn (ProjectParticipant $p) => $this->isFirstOrderHeadOrPartnerParticipant($p));
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

    /** @return Collection<int, ProjectParticipant> */
    private function participantsForUserOnProject(int $userId, Project $project): Collection
    {
        return ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('is_active', true)
            ->whereHas('counterparty', function ($q) use ($userId): void {
                $q->where('user_id', $userId)->where('is_active', true);
            })
            ->get();
    }

    private function isFirstOrderHeadOrPartnerParticipant(ProjectParticipant $p): bool
    {
        if (strtolower((string) $p->level) !== 'first') {
            return false;
        }

        return in_array($p->project_role_code, [
            ProjectRoleCode::PROJECT_HEAD->value,
            ProjectRoleCode::PARTNER->value,
        ], true);
    }
}
