<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\User;
use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\WalletFactoryService;
use Database\Seeders\CompanyRoleSeeder;
use Database\Seeders\ProjectRoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * ТЗ-10A: статьи расходов — валидация долей, права PARTNER, soft-delete.
 */
final class ProjectExpenseItemsCompanyWorkspaceTest extends TestCase
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

    /** @return array{0: User, 1: Company, 2: Counterparty} */
    private function createOwnerWithCompany(): array
    {
        $owner = User::factory()->create();
        $company = Company::query()->create([
            'name' => 'Co EI',
            'created_by_user_id' => $owner->id,
            'is_active' => true,
        ]);
        $ownerCp = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $owner->id,
            'company_role_code' => CompanyRoleCode::OWNER->value,
            'is_active' => true,
        ]);

        return [$owner, $company, $ownerCp];
    }

    private function createProjectWithOwnerHead(Company $company, Counterparty $ownerCp): Project
    {
        $project = Project::query()->create([
            'company_id' => $company->id,
            'name' => 'EI Project',
            'progress_percent' => 0,
            'is_active' => true,
        ]);
        $head = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $ownerCp->id,
            'project_role_code' => ProjectRoleCode::PROJECT_HEAD->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        app(WalletFactoryService::class)->createForParticipant($head);

        return $project;
    }

    private function createPartnerCounterparty(Company $company, User $partner): Counterparty
    {
        return Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $partner->id,
            'company_role_code' => CompanyRoleCode::PARTNER->value,
            'is_active' => true,
        ]);
    }

    private function attachPartnerFirstOrder(Project $project, Counterparty $partnerCp): ProjectParticipant
    {
        $pp = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $partnerCp->id,
            'project_role_code' => ProjectRoleCode::PARTNER->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        app(WalletFactoryService::class)->createForParticipant($pp);

        return $pp;
    }

    public function test_create_rejects_profit_shares_sum_not_100(): void
    {
        [$owner, $company, $ownerCp] = $this->createOwnerWithCompany();
        $project = $this->createProjectWithOwnerHead($company, $ownerCp);

        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $res = $this->postJson("{$base}/projects/{$project->id}/expense-items", [
            'name' => 'Bad shares',
            'profit_shares' => [
                ['counterparty_id' => $ownerCp->id, 'percent' => '60.00'],
            ],
            'markup_enabled' => false,
        ]);

        $res->assertStatus(422)->assertJsonPath('error.fields.profit_shares.0', 'Сумма долей должна быть ровно 100,00%.');
    }

    public function test_create_rejects_markup_shares_sum_not_100_when_markup_enabled(): void
    {
        [$owner, $company, $ownerCp] = $this->createOwnerWithCompany();
        $project = $this->createProjectWithOwnerHead($company, $ownerCp);

        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $res = $this->postJson("{$base}/projects/{$project->id}/expense-items", [
            'name' => 'Bad markup',
            'profit_shares' => [
                ['counterparty_id' => $ownerCp->id, 'percent' => '100.00'],
            ],
            'markup_enabled' => true,
            'markup_percent' => '10.00',
            'markup_shares' => [
                ['counterparty_id' => $ownerCp->id, 'percent' => '40.00'],
            ],
        ]);

        $res->assertStatus(422)->assertJsonPath('error.fields.markup_shares.0', 'Сумма долей должна быть ровно 100,00%.');
    }

    public function test_partner_first_order_cannot_create_expense_item(): void
    {
        [$owner, $company, $ownerCp] = $this->createOwnerWithCompany();
        $project = $this->createProjectWithOwnerHead($company, $ownerCp);
        $partner = User::factory()->create();
        $partnerCp = $this->createPartnerCounterparty($company, $partner);
        $this->attachPartnerFirstOrder($project, $partnerCp);

        Sanctum::actingAs($partner);
        $base = "/api/company-workspace/{$company->id}";
        $this->postJson("{$base}/projects/{$project->id}/expense-items", [
            'name' => 'From partner',
            'profit_shares' => [
                ['counterparty_id' => $partnerCp->id, 'percent' => '100.00'],
            ],
            'markup_enabled' => false,
        ])->assertForbidden();
    }

    public function test_partner_first_order_cannot_patch_expense_item(): void
    {
        [$owner, $company, $ownerCp] = $this->createOwnerWithCompany();
        $project = $this->createProjectWithOwnerHead($company, $ownerCp);
        $partner = User::factory()->create();
        $partnerCp = $this->createPartnerCounterparty($company, $partner);
        $this->attachPartnerFirstOrder($project, $partnerCp);

        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $itemId = (int) $this->postJson("{$base}/projects/{$project->id}/expense-items", [
            'name' => 'Owner item',
            'profit_shares' => [
                ['counterparty_id' => $ownerCp->id, 'percent' => '100.00'],
            ],
            'markup_enabled' => false,
        ])->assertCreated()->json('data.expense_item.id');

        Sanctum::actingAs($partner);
        $this->patchJson("{$base}/projects/{$project->id}/expense-items/{$itemId}", [
            'name' => 'Hacked',
            'profit_shares' => [
                ['counterparty_id' => $ownerCp->id, 'percent' => '100.00'],
            ],
            'markup_enabled' => false,
        ])->assertForbidden();
    }

    public function test_soft_deleted_expense_item_hidden_from_list(): void
    {
        [$owner, $company, $ownerCp] = $this->createOwnerWithCompany();
        $project = $this->createProjectWithOwnerHead($company, $ownerCp);

        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $itemId = (int) $this->postJson("{$base}/projects/{$project->id}/expense-items", [
            'name' => 'To delete',
            'profit_shares' => [
                ['counterparty_id' => $ownerCp->id, 'percent' => '100.00'],
            ],
            'markup_enabled' => false,
        ])->assertCreated()->json('data.expense_item.id');

        $this->getJson("{$base}/projects/{$project->id}/expense-items")->assertOk();
        $idsBefore = array_column($this->getJson("{$base}/projects/{$project->id}/expense-items")->json('data.expense_items'), 'id');
        self::assertContains($itemId, $idsBefore);

        $this->deleteJson("{$base}/projects/{$project->id}/expense-items/{$itemId}")->assertOk();

        $idsAfter = array_column($this->getJson("{$base}/projects/{$project->id}/expense-items")->json('data.expense_items'), 'id');
        self::assertNotContains($itemId, $idsAfter);
    }
}
