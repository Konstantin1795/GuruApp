<?php

namespace App\Modules\Workspaces\Services;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Projects\Models\ProjectParticipant;

final class WorkspaceResolver
{
    /**
     * @return array{
     *   company_workspaces: array<int, array{company: array{id:int,name:string}, role: string}>,
     *   personal_workspace: array{available: bool, roles: array<int,string>, companies_count: int, projects_count: int}
     * }
     */
    public function resolveForUserId(int $userId): array
    {
        $companyWorkspaces = Counterparty::query()
            ->select(['counterparties.company_id', 'counterparties.company_role_code', 'companies.name'])
            ->join('companies', 'companies.id', '=', 'counterparties.company_id')
            ->where('counterparties.user_id', $userId)
            ->where('counterparties.is_active', true)
            ->whereIn('counterparties.company_role_code', [
                CompanyRoleCode::OWNER->value,
                CompanyRoleCode::PARTNER->value,
            ])
            ->orderByDesc('counterparties.company_id')
            ->get()
            ->map(fn ($row) => [
                'company' => [
                    'id' => (int) $row->company_id,
                    'name' => (string) $row->name,
                ],
                'role' => (string) $row->company_role_code,
            ])
            ->values()
            ->all();

        $personalRoles = Counterparty::query()
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->whereIn('company_role_code', [
                CompanyRoleCode::EMPLOYEE->value,
                CompanyRoleCode::CONTRACTOR->value,
                CompanyRoleCode::SUPPLIER->value,
                CompanyRoleCode::CUSTOMER->value,
            ])
            ->pluck('company_role_code')
            ->unique()
            ->values()
            ->all();

        $personalAvailable = count($personalRoles) > 0;

        $companiesCount = $personalAvailable
            ? Counterparty::query()
                ->where('user_id', $userId)
                ->where('is_active', true)
                ->whereIn('company_role_code', $personalRoles)
                ->pluck('company_id')
                ->unique()
                ->count()
            : 0;

        $projectsCount = $personalAvailable
            ? ProjectParticipant::query()
                ->whereHas('counterparty', fn ($q) => $q->where('user_id', $userId)->where('is_active', true))
                ->where('is_active', true)
                ->pluck('project_id')
                ->unique()
                ->count()
            : 0;

        return [
            'company_workspaces' => $companyWorkspaces,
            'personal_workspace' => [
                'available' => $personalAvailable,
                'roles' => $personalRoles,
                'companies_count' => (int) $companiesCount,
                'projects_count' => (int) $projectsCount,
            ],
        ];
    }
}

