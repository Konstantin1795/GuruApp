<?php

namespace App\Modules\Projects\Services;

use App\Models\User;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Models\PriceList;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Models\ProjectPriceList;
use Illuminate\Database\Eloquent\Builder;

/**
 * ТЗ-10B: доступ к прайс-листам компании и прикреплениям к проектам.
 */
final class PriceListAccessService
{
    public function __construct(
        private readonly ProjectVisibilityService $visibility,
    ) {}

    public function companyCounterparty(int $userId, int $companyId): ?Counterparty
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

    public function isOwner(?Counterparty $cp): bool
    {
        return $cp !== null && $cp->company_role_code === CompanyRoleCode::OWNER->value;
    }

    /** PARTNER (или OWNER) является PROJECT_HEAD first-order хотя бы в одном проекте компании. */
    public function isProjectHeadSomewhereInCompany(int $userId, int $companyId): bool
    {
        $cp = $this->companyCounterparty($userId, $companyId);
        if (! $cp) {
            return false;
        }

        if ($cp->company_role_code === CompanyRoleCode::OWNER->value) {
            return true;
        }

        return ProjectParticipant::query()
            ->where('project_role_code', ProjectRoleCode::PROJECT_HEAD->value)
            ->where('is_active', true)
            ->whereRaw('LOWER(level) = ?', ['first'])
            ->where('counterparty_id', (int) $cp->id)
            ->whereHas('project', fn (Builder $q) => $q->where('company_id', $companyId))
            ->exists();
    }

    public function activeOwnPriceListId(int $companyId, int $counterpartyId): ?int
    {
        $id = PriceList::query()
            ->where('company_id', $companyId)
            ->where('created_by_counterparty_id', $counterpartyId)
            ->visible()
            ->value('id');

        return $id !== null ? (int) $id : null;
    }

    /**
     * @return array{
     *   can_view_company_price_list_library: bool,
     *   can_create_company_price_list: bool,
     *   company_price_list_create_blocked_reason: string|null,
     *   active_own_price_list_id: int|null
     * }
     */
    public function companyLibraryFlags(User $user, int $companyId): array
    {
        $cp = $this->companyCounterparty((int) $user->id, $companyId);
        if (! $cp) {
            return [
                'can_view_company_price_list_library' => false,
                'can_create_company_price_list' => false,
                'company_price_list_create_blocked_reason' => null,
                'active_own_price_list_id' => null,
            ];
        }

        $isOwner = $this->isOwner($cp);
        $isPartner = $cp->company_role_code === CompanyRoleCode::PARTNER->value;
        $isHeadSomewhere = $this->isProjectHeadSomewhereInCompany((int) $user->id, $companyId);
        $ownId = $isOwner ? null : $this->activeOwnPriceListId($companyId, (int) $cp->id);

        $canCreate = $isOwner || ($isPartner && $isHeadSomewhere && $ownId === null);

        $blocked = null;
        if (! $isOwner && $isPartner && ! $isHeadSomewhere) {
            $blocked = 'partner_not_project_head';
        } elseif (! $isOwner && $isPartner && $ownId !== null) {
            $blocked = 'partner_already_has_active_list';
        }

        return [
            'can_view_company_price_list_library' => true,
            'can_create_company_price_list' => $canCreate,
            'company_price_list_create_blocked_reason' => $blocked,
            'active_own_price_list_id' => $ownId,
        ];
    }

    public function priceListsIndexQuery(User $user, int $companyId): Builder
    {
        $cp = $this->companyCounterparty((int) $user->id, $companyId);
        if (! $cp) {
            return PriceList::query()->whereRaw('1 = 0');
        }

        $q = PriceList::query()
            ->where('company_id', $companyId)
            ->visible();

        if ($this->isOwner($cp)) {
            return $q;
        }

        return $q->where('created_by_counterparty_id', (int) $cp->id);
    }

    public function assertCanViewPriceList(User $user, int $companyId, PriceList $priceList): void
    {
        $this->assertSameCompany($companyId, $priceList);
        if ($this->canViewPriceList($user, $companyId, $priceList)) {
            return;
        }

        abort(403, 'Forbidden.');
    }

    public function canViewPriceList(User $user, int $companyId, PriceList $priceList): bool
    {
        $cp = $this->companyCounterparty((int) $user->id, $companyId);
        if (! $cp) {
            return false;
        }

        if ($this->isOwner($cp)) {
            return true;
        }

        if ((int) $priceList->created_by_counterparty_id === (int) $cp->id) {
            return true;
        }

        return ProjectPriceList::query()
            ->where('price_list_id', (int) $priceList->id)
            ->whereHas('project', fn (Builder $q) => $q->where('company_id', $companyId))
            ->whereHas('project.participants', function (Builder $q) use ($cp): void {
                $q->where('counterparty_id', (int) $cp->id)
                    ->where('project_role_code', ProjectRoleCode::PROJECT_HEAD->value)
                    ->where('is_active', true)
                    ->whereRaw('LOWER(level) = ?', ['first']);
            })
            ->exists();
    }

    public function assertCanEditPriceList(User $user, int $companyId, PriceList $priceList): void
    {
        $this->assertSameCompany($companyId, $priceList);
        $cp = $this->companyCounterparty((int) $user->id, $companyId);
        if (! $cp) {
            abort(403, 'Forbidden.');
        }

        if ($this->isOwner($cp)) {
            return;
        }

        if ((int) $priceList->created_by_counterparty_id === (int) $cp->id) {
            return;
        }

        abort(403, 'Forbidden.');
    }

    public function canEditPriceList(User $user, int $companyId, PriceList $priceList): bool
    {
        if ((int) $priceList->company_id !== $companyId) {
            return false;
        }

        $cp = $this->companyCounterparty((int) $user->id, $companyId);
        if (! $cp) {
            return false;
        }

        if ($this->isOwner($cp)) {
            return true;
        }

        return (int) $priceList->created_by_counterparty_id === (int) $cp->id;
    }

    public function assertCanCreatePriceList(User $user, int $companyId): void
    {
        $flags = $this->companyLibraryFlags($user, $companyId);
        if (! $flags['can_create_company_price_list']) {
            abort(403, 'Forbidden.');
        }
    }

    public function assertCanDeletePriceList(User $user, int $companyId, PriceList $priceList): void
    {
        $this->assertCanEditPriceList($user, $companyId, $priceList);
    }

    public function assertCanManageProjectPriceListAttachments(User $user, int $companyId, Project $project): void
    {
        $this->visibility->assertCanManageCompanyProject((int) $user->id, $companyId, (int) $project->id);
    }

    /**
     * OWNER — любой активный прайс компании; PARTNER-РП — только свой активный прайс.
     */
    public function assertCanAttachPriceListToProject(User $user, int $companyId, Project $project, PriceList $priceList): void
    {
        $this->assertSameCompany($companyId, $priceList);
        $this->assertCanManageProjectPriceListAttachments($user, $companyId, $project);

        $cp = $this->companyCounterparty((int) $user->id, $companyId);
        if (! $cp) {
            abort(403, 'Forbidden.');
        }

        if (! $priceList->is_active || $priceList->trashed()) {
            abort(422, 'Price list is not available.');
        }

        if ($this->isOwner($cp)) {
            return;
        }

        if ((int) $priceList->created_by_counterparty_id !== (int) $cp->id) {
            abort(403, 'Forbidden.');
        }
    }

    public function assertCanDetachPriceListFromProject(User $user, int $companyId, Project $project, PriceList $priceList): void
    {
        $this->assertSameCompany($companyId, $priceList);
        $this->visibility->assertCanAccessCompanyProject((int) $user->id, $companyId, (int) $project->id);

        $cp = $this->companyCounterparty((int) $user->id, $companyId);
        if (! $cp) {
            abort(403, 'Forbidden.');
        }

        if ($this->isOwner($cp)) {
            return;
        }

        $isHeadOnProject = ProjectParticipant::query()
            ->where('project_id', (int) $project->id)
            ->where('counterparty_id', (int) $cp->id)
            ->where('project_role_code', ProjectRoleCode::PROJECT_HEAD->value)
            ->where('is_active', true)
            ->whereRaw('LOWER(level) = ?', ['first'])
            ->exists();

        if (! $isHeadOnProject) {
            abort(403, 'Forbidden.');
        }

        if ((int) $priceList->created_by_counterparty_id !== (int) $cp->id) {
            abort(403, 'Forbidden.');
        }
    }

    /**
     * @return array{can_view_project_price_lists: bool, can_manage_project_price_list_attachments: bool}
     */
    public function projectSummaryFlags(User $user, int $companyId, Project $project): array
    {
        $expense = app(ProjectExpenseItemAccessService::class);

        $canViewProject = false;
        try {
            $this->visibility->assertCanAccessCompanyProject((int) $user->id, $companyId, (int) $project->id);
            $canViewProject = $expense->canView($user, $companyId, $project);
        } catch (\Throwable) {
            $canViewProject = false;
        }

        $canManage = false;
        try {
            $this->assertCanManageProjectPriceListAttachments($user, $companyId, $project);
            $canManage = true;
        } catch (\Throwable) {
            $canManage = false;
        }

        return [
            'can_view_project_price_lists' => $canViewProject,
            'can_manage_project_price_list_attachments' => $canManage,
        ];
    }

    private function assertSameCompany(int $companyId, PriceList $priceList): void
    {
        if ((int) $priceList->company_id !== $companyId) {
            abort(404, 'Not found.');
        }
    }
}
