<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\User;
use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Models\ProjectParticipant;
use Database\Seeders\CompanyRoleSeeder;
use Database\Seeders\ProjectRoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class CreateProjectPartnerCompanyWorkspaceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        if (! extension_loaded('pdo_sqlite')) {
            $this->markTestSkipped(
                'Расширение PHP pdo_sqlite не загружено; для Feature-тестов с RefreshDatabase нужен SQLite (см. phpunit.xml).',
            );
        }

        parent::setUp();
        $this->seed(CompanyRoleSeeder::class);
        $this->seed(ProjectRoleSeeder::class);
    }

    public function test_partner_can_create_project_and_becomes_project_head(): void
    {
        $owner = User::factory()->create();
        $partnerUser = User::factory()->create();
        $company = Company::query()->create([
            'name' => 'Co',
            'created_by_user_id' => $owner->id,
            'is_active' => true,
        ]);
        Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $owner->id,
            'company_role_code' => CompanyRoleCode::OWNER->value,
            'is_active' => true,
        ]);
        $partnerCp = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $partnerUser->id,
            'company_role_code' => CompanyRoleCode::PARTNER->value,
            'is_active' => true,
        ]);

        Sanctum::actingAs($partnerUser);
        $base = "/api/company-workspace/{$company->id}";
        $res = $this->postJson("{$base}/projects", ['name' => 'Проект партнёра']);
        $res->assertOk()->assertJsonPath('ok', true);
        $projectId = (int) $res->json('data.project.id');
        $this->assertGreaterThan(0, $projectId);

        $this->assertTrue(
            ProjectParticipant::query()
                ->where('project_id', $projectId)
                ->where('counterparty_id', (int) $partnerCp->id)
                ->where('project_role_code', ProjectRoleCode::PROJECT_HEAD->value)
                ->where('level', 'first')
                ->where('is_active', true)
                ->exists(),
        );
    }
}
