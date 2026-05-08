<?php

namespace Database\Seeders;

use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Models\CompanyRole;
use Illuminate\Database\Seeder;

final class CompanyRoleSeeder extends Seeder
{
    public function run(): void
    {
        foreach (CompanyRoleCode::cases() as $role) {
            CompanyRole::query()->updateOrCreate(
                ['code' => $role->value],
                ['description' => null],
            );
        }
    }
}

