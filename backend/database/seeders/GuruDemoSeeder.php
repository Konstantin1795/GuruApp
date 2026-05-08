<?php

namespace Database\Seeders;

use App\Models\User;
use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

final class GuruDemoSeeder extends Seeder
{
    public function run(): void
    {
        // User #1: OWNER in company workspace + PROJECT_HEAD in a project
        $ownerUser = User::query()->updateOrCreate(
            ['email' => 'owner@guru.local'],
            [
                'name' => 'Guru Owner',
                'password' => Hash::make('password'),
            ]
        );

        // User #2: EMPLOYEE (personal workspace) in same company
        $employeeUser = User::query()->updateOrCreate(
            ['email' => 'employee@guru.local'],
            [
                'name' => 'Guru Employee',
                'password' => Hash::make('password'),
            ]
        );

        // User #3: PARTNER (company workspace) in same company
        $partnerUser = User::query()->updateOrCreate(
            ['email' => 'partner@guru.local'],
            [
                'name' => 'Guru Partner',
                'password' => Hash::make('password'),
            ]
        );

        $company = Company::query()->updateOrCreate(
            ['name' => 'GURU Demo Company'],
            [
                'created_by_user_id' => $ownerUser->id,
                'is_active' => true,
            ]
        );

        $ownerCounterparty = Counterparty::query()->updateOrCreate(
            [
                'company_id' => $company->id,
                'user_id' => $ownerUser->id,
            ],
            [
                'company_role_code' => CompanyRoleCode::OWNER->value,
                'is_active' => true,
            ]
        );

        $partnerCounterparty = Counterparty::query()->updateOrCreate(
            [
                'company_id' => $company->id,
                'user_id' => $partnerUser->id,
            ],
            [
                'company_role_code' => CompanyRoleCode::PARTNER->value,
                'is_active' => true,
            ]
        );

        $employeeCounterparty = Counterparty::query()->updateOrCreate(
            [
                'company_id' => $company->id,
                'user_id' => $employeeUser->id,
            ],
            [
                'company_role_code' => CompanyRoleCode::EMPLOYEE->value,
                'is_active' => true,
            ]
        );

        $project = Project::query()->updateOrCreate(
            [
                'company_id' => $company->id,
                'name' => 'GURU Demo Project',
            ],
            [
                'progress_percent' => 0,
                'is_active' => true,
            ]
        );

        ProjectParticipant::query()->updateOrCreate(
            [
                'project_id' => $project->id,
                'counterparty_id' => $ownerCounterparty->id,
            ],
            [
                'project_role_code' => ProjectRoleCode::PROJECT_HEAD->value,
                'level' => 'first',
                'is_active' => true,
            ]
        );

        ProjectParticipant::query()->updateOrCreate(
            [
                'project_id' => $project->id,
                'counterparty_id' => $employeeCounterparty->id,
            ],
            [
                'project_role_code' => ProjectRoleCode::EMPLOYEE->value,
                'level' => 'first',
                'is_active' => true,
            ]
        );

        // Optional: partner participant is not required for foundation checks,
        // but keeping Counterparty PARTNER seeded and idempotent.
        ProjectParticipant::query()->updateOrCreate(
            [
                'project_id' => $project->id,
                'counterparty_id' => $partnerCounterparty->id,
            ],
            [
                'project_role_code' => ProjectRoleCode::PARTNER->value,
                'level' => 'first',
                'is_active' => true,
            ]
        );
    }
}

