<?php

namespace Database\Seeders;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Dictionaries\Models\ProjectRole;
use Illuminate\Database\Seeder;

final class ProjectRoleSeeder extends Seeder
{
    public function run(): void
    {
        foreach (ProjectRoleCode::cases() as $role) {
            ProjectRole::query()->updateOrCreate(
                ['code' => $role->value],
                ['description' => null],
            );
        }
    }
}

