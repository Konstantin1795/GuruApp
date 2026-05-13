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
 * ТЗ-07: флаги видимости для экрана проекта.
 */
final class ProjectSummaryVisibilityService
{
    /**
     * @return array{
     *   can_view_internal_metrics: bool,
     *   can_view_participants: bool,
     *   can_create_income: bool,
     *   can_create_transfer: bool,
     *   can_create_report: bool
     * }
     */
    public function flagsForCompanyWorkspace(User $user, int $companyId, Project $project): array
    {
        $userId = (int) $user->id;
        $counterparty = $this->companyCounterparty($userId, $companyId);

        $participants = $this->participantsForUserOnProject($userId, $project);

        $isOwner = $counterparty !== null
            && $counterparty->company_role_code === CompanyRoleCode::OWNER->value;

        $canViewInternal = $isOwner || $this->hasFirstOrderHeadOrPartner($participants);

        $onlyCustomer = $this->isOnlyCustomerRole($participants);

        return [
            'can_view_internal_metrics' => $canViewInternal,
            'can_view_participants'     => ! $onlyCustomer,
            'can_create_income'         => $this->canCreateIncomeCompany($participants),
            'can_create_transfer'       => $this->canCreateTransferCompany($participants),
            'can_create_report'         => $this->canCreateReportCompany($participants),
        ];
    }

    /**
     * Личный кабинет / заказчик: без внутренних метрик и управления из ТЗ-07 §19.
     *
     * @return array{
     *   can_view_internal_metrics: bool,
     *   can_view_participants: bool,
     *   can_create_income: bool,
     *   can_create_transfer: bool,
     *   can_create_report: bool
     * }
     */
    public function flagsForPersonalWorkspace(User $user, Project $project): array
    {
        $participants = $this->participantsForUserOnProject((int) $user->id, $project);

        $onlyCustomer = $this->isOnlyCustomerRole($participants);
        $headOrPartnerFirst = $this->hasFirstOrderHeadOrPartner($participants);

        return [
            'can_view_internal_metrics' => $headOrPartnerFirst,
            'can_view_participants'     => ! $onlyCustomer,
            'can_create_income'         => false,
            'can_create_transfer'       => $this->canCreateTransferPersonal($participants),
            'can_create_report'         => false,
        ];
    }

    private function companyCounterparty(int $userId, int $companyId): ?Counterparty
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

    /** @param Collection<int, ProjectParticipant> $participants */
    private function isOnlyCustomerRole(Collection $participants): bool
    {
        if ($participants->isEmpty()) {
            return false;
        }

        return $participants->every(
            fn (ProjectParticipant $p) => $p->project_role_code === ProjectRoleCode::CUSTOMER->value,
        );
    }

    /** @param Collection<int, ProjectParticipant> $participants */
    private function hasFirstOrderHeadOrPartner(Collection $participants): bool
    {
        foreach ($participants as $p) {
            if (strtolower((string) $p->level) !== 'first') {
                continue;
            }
            if (in_array($p->project_role_code, [
                ProjectRoleCode::PROJECT_HEAD->value,
                ProjectRoleCode::PARTNER->value,
            ], true)) {
                return true;
            }
        }

        return false;
    }

    /** @param Collection<int, ProjectParticipant> $participants */
    private function canCreateIncomeCompany(Collection $participants): bool
    {
        foreach ($participants as $p) {
            if (strtolower((string) $p->level) !== 'first') {
                continue;
            }
            if (in_array($p->project_role_code, [
                ProjectRoleCode::PROJECT_HEAD->value,
                ProjectRoleCode::PARTNER->value,
            ], true)) {
                return true;
            }
        }

        return false;
    }

    /** @param Collection<int, ProjectParticipant> $participants */
    private function canCreateTransferCompany(Collection $participants): bool
    {
        return $participants->isNotEmpty();
    }

    /** @param Collection<int, ProjectParticipant> $participants */
    private function canCreateTransferPersonal(Collection $participants): bool
    {
        foreach ($participants as $p) {
            if (strtolower((string) $p->level) !== 'first') {
                continue;
            }
            if ($p->project_role_code === ProjectRoleCode::EMPLOYEE->value) {
                return true;
            }
            if (in_array($p->project_role_code, [
                ProjectRoleCode::PROJECT_HEAD->value,
                ProjectRoleCode::PARTNER->value,
            ], true)) {
                return true;
            }
        }

        return false;
    }

    /** @param Collection<int, ProjectParticipant> $participants */
    private function canCreateReportCompany(Collection $participants): bool
    {
        foreach ($participants as $p) {
            if (strtolower((string) $p->level) !== 'first') {
                continue;
            }
            if (in_array($p->project_role_code, [
                ProjectRoleCode::PROJECT_HEAD->value,
                ProjectRoleCode::PARTNER->value,
                ProjectRoleCode::EMPLOYEE->value,
            ], true)) {
                return true;
            }
        }

        return false;
    }
}
