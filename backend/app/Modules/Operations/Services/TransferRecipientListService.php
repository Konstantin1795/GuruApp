<?php

namespace App\Modules\Operations\Services;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\TransferTargetType;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Support\Collection;

final class TransferRecipientListService
{
    /**
     * ТЗ-05.2 v3 §9: список получателей для UI в рамках project_id / company_id.
     *
     * @return Collection<int, array<string, mixed>>
     */
    public function list(Project $project, int $companyId, TransferTargetType $type, ?int $excludeProjectParticipantId = null): Collection
    {
        return match ($type) {
            TransferTargetType::ACCOUNTABLE_BALANCE => $this->accountableParticipants($project, $excludeProjectParticipantId),
            TransferTargetType::PERSONAL_BALANCE    => $this->personalCounterparties($companyId),
        };
    }

    /**
     * @return Collection<int, array<string, mixed>>
     */
    private function accountableParticipants(Project $project, ?int $excludeProjectParticipantId = null): Collection
    {
        $allowed = [
            ProjectRoleCode::PROJECT_HEAD->value,
            ProjectRoleCode::PARTNER->value,
            ProjectRoleCode::EMPLOYEE->value,
        ];

        $q = ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('is_active', true)
            ->whereRaw('LOWER(level) = ?', ['first'])
            ->whereIn('project_role_code', $allowed)
            ->with(['counterparty.user'])
            ->orderBy('id');

        if ($excludeProjectParticipantId !== null) {
            $q->where('id', '!=', $excludeProjectParticipantId);
        }

        return $q->get()
            ->map(fn (ProjectParticipant $p) => [
                'project_participant_id' => $p->id,
                'display_name'           => $p->counterparty?->full_name
                    ?? optional($p->counterparty?->user)->name
                    ?? $p->counterparty?->email
                    ?? ('#'.$p->id),
                'project_role_code'      => $p->project_role_code,
            ]);
    }

    /**
     * @return Collection<int, array<string, mixed>>
     */
    private function personalCounterparties(int $companyId): Collection
    {
        $allowed = [
            CompanyRoleCode::OWNER->value,
            CompanyRoleCode::PARTNER->value,
            CompanyRoleCode::EMPLOYEE->value,
            CompanyRoleCode::SUPPLIER->value,
            CompanyRoleCode::CONTRACTOR->value,
            CompanyRoleCode::CUSTOMER->value,
        ];

        return Counterparty::query()
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->whereIn('company_role_code', $allowed)
            ->orderBy('id')
            ->get()
            ->map(fn (Counterparty $c) => [
                'counterparty_id'   => $c->id,
                'display_name'      => $c->full_name ?? $c->email ?? ('#'.$c->id),
                'company_role_code' => $c->company_role_code,
            ]);
    }
}
