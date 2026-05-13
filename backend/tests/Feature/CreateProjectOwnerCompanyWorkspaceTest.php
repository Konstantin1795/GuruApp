<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\User;
use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Models\ProjectParticipantWallet;
use Database\Seeders\CompanyRoleSeeder;
use Database\Seeders\ProjectRoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class CreateProjectOwnerCompanyWorkspaceTest extends TestCase
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

    public function test_owner_creates_project_becomes_project_head_and_has_wallet(): void
    {
        $owner = User::factory()->create();
        $company = Company::query()->create([
            'name' => 'Co Owner',
            'created_by_user_id' => $owner->id,
            'is_active' => true,
        ]);
        $ownerCp = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $owner->id,
            'company_role_code' => CompanyRoleCode::OWNER->value,
            'is_active' => true,
        ]);

        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $res = $this->postJson("{$base}/projects", ['name' => 'Проект OWNER']);
        $res->assertOk()->assertJsonPath('ok', true);
        $projectId = (int) $res->json('data.project.id');
        $this->assertGreaterThan(0, $projectId);

        $head = ProjectParticipant::query()
            ->where('project_id', $projectId)
            ->where('counterparty_id', (int) $ownerCp->id)
            ->where('project_role_code', ProjectRoleCode::PROJECT_HEAD->value)
            ->where('level', 'first')
            ->where('is_active', true)
            ->first();
        $this->assertNotNull($head);

        $wallet = ProjectParticipantWallet::query()->where('project_participant_id', (int) $head->id)->first();
        $this->assertNotNull($wallet);
        self::assertSame('0.00', (string) $wallet->accountable_balance);
        self::assertSame('0.00', (string) $wallet->personal_balance);
    }

    public function test_owner_creates_project_with_customer_gets_first_order_customer_and_wallet(): void
    {
        $owner = User::factory()->create();
        $customerUser = User::factory()->create();
        $company = Company::query()->create([
            'name' => 'Co With Customer',
            'created_by_user_id' => $owner->id,
            'is_active' => true,
        ]);
        $ownerCp = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $owner->id,
            'company_role_code' => CompanyRoleCode::OWNER->value,
            'is_active' => true,
        ]);
        $customerCp = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $customerUser->id,
            'company_role_code' => CompanyRoleCode::EMPLOYEE->value,
            'is_active' => true,
        ]);

        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $res = $this->postJson("{$base}/projects", [
            'name' => 'С заказчиком',
            'customer_counterparty_id' => $customerCp->id,
        ]);
        $res->assertOk();
        $projectId = (int) $res->json('data.project.id');

        $customerPp = ProjectParticipant::query()
            ->where('project_id', $projectId)
            ->where('counterparty_id', (int) $customerCp->id)
            ->where('project_role_code', ProjectRoleCode::CUSTOMER->value)
            ->where('level', 'first')
            ->where('is_active', true)
            ->first();
        $this->assertNotNull($customerPp);

        $customerWallet = ProjectParticipantWallet::query()
            ->where('project_participant_id', (int) $customerPp->id)
            ->first();
        $this->assertNotNull($customerWallet);
        self::assertSame('0.00', (string) $customerWallet->accountable_balance);
    }
}
