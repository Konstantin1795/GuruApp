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
            ->join('project_participants', 'project_participants.counterparty_id', '=', 'counterparties.id')
            ->where('counterparties.user_id', $userId)
            ->where('counterparties.is_active', true)
            ->where('project_participants.is_active', true)
            ->whereIn('counterparties.company_role_code', [
                CompanyRoleCode::EMPLOYEE->value,
                CompanyRoleCode::CONTRACTOR->value,
                CompanyRoleCode::SUPPLIER->value,
                CompanyRoleCode::CUSTOMER->value,
            ])
            ->pluck('counterparties.company_role_code')
            ->unique()
            ->values()
            ->all();

        $personalAvailable = count($personalRoles) > 0;

        $companiesCount = $personalAvailable
            ? Counterparty::query()
                ->join('project_participants', 'project_participants.counterparty_id', '=', 'counterparties.id')
                ->where('counterparties.user_id', $userId)
                ->where('counterparties.is_active', true)
                ->where('project_participants.is_active', true)
                ->whereIn('counterparties.company_role_code', $personalRoles)
                ->pluck('counterparties.company_id')
                ->unique()
                ->count()
            : 0;

        $projectsCount = $personalAvailable
            ? ProjectParticipant::query()
                ->whereHas('counterparty', fn ($q) => $q
                    ->where('user_id', $userId)
                    ->where('is_active', true)
                    ->whereIn('company_role_code', $personalRoles))
                ->where('is_active', true)
                ->pluck('project_id')
                ->unique()
                ->count()
            : 0;

        $items = [];
        foreach ($companyWorkspaces as $workspace) {
            $items[] = [
                'type' => 'company',
                'company' => $workspace['company'],
                'company_role' => $workspace['role'],
                'label' => $workspace['role'],
            ];
        }

        if (in_array(CompanyRoleCode::CUSTOMER->value, $personalRoles, true)) {
            $items[] = [
                'type' => 'customer',
                'label' => 'CUSTOMER',
                'companies_count' => (int) $companiesCount,
                'projects_count' => (int) $projectsCount,
            ];
        }

        $workerRoles = array_values(array_intersect($personalRoles, [
            CompanyRoleCode::EMPLOYEE->value,
            CompanyRoleCode::SUPPLIER->value,
            CompanyRoleCode::CONTRACTOR->value,
        ]));
        if ($workerRoles !== []) {
            $items[] = [
                'type' => 'worker',
                'label' => 'WORKER',
                'company_roles' => $workerRoles,
                'companies_count' => (int) $companiesCount,
                'projects_count' => (int) $projectsCount,
            ];
        }

        return [
            'company_workspaces' => $companyWorkspaces,
            'personal_workspace' => [
                'available' => $personalAvailable,
                'roles' => $personalRoles,
                'companies_count' => (int) $companiesCount,
                'projects_count' => (int) $projectsCount,
            ],
            'items' => $items,
            'can_create_company' => true,
        ];
    }
}

