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
use App\Modules\Projects\Models\Unit;
use App\Modules\Projects\Services\WalletFactoryService;
use Database\Seeders\CompanyRoleSeeder;
use Database\Seeders\ProjectRoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class PriceListsCompanyWorkspaceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        if (! extension_loaded('pdo_sqlite')) {
            $this->markTestSkipped(
                'Расширение PHP pdo_sqlite не загружено; для Feature-тестов с RefreshDatabase нужен SQLite (см. phpunit.xml). Включите extension=pdo_sqlite в php.ini или запускайте тесты в окружении с этим расширением.',
            );
        }

        parent::setUp();
        $this->seed(CompanyRoleSeeder::class);
        $this->seed(ProjectRoleSeeder::class);
    }

    private function systemUnitId(): int
    {
        $id = Unit::query()->where('is_system', true)->whereNull('company_id')->value('id');

        return (int) $id;
    }

    /** @return array{User, Company, Counterparty} */
    private function createOwnerWithCompany(): array
    {
        $owner = User::factory()->create();
        $company = Company::query()->create([
            'name' => 'Test Co',
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

    private function createPartnerCounterparty(Company $company, User $partner): Counterparty
    {
        return Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $partner->id,
            'company_role_code' => CompanyRoleCode::PARTNER->value,
            'is_active' => true,
        ]);
    }

    private function createProjectWithOwnerHead(Company $company, Counterparty $ownerCp): Project
    {
        $project = Project::query()->create([
            'company_id' => $company->id,
            'name' => 'Owner Head Project',
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

    /** Проект, где партнёр — единственный PROJECT_HEAD (правила ТЗ-10B). */
    private function createProjectWithPartnerHead(Company $company, Counterparty $partnerCp): Project
    {
        $project = Project::query()->create([
            'company_id' => $company->id,
            'name' => 'Partner Head Project',
            'progress_percent' => 0,
            'is_active' => true,
        ]);
        $head = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $partnerCp->id,
            'project_role_code' => ProjectRoleCode::PROJECT_HEAD->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        app(WalletFactoryService::class)->createForParticipant($head);

        return $project;
    }

    public function test_owner_can_create_multiple_price_lists_in_company(): void
    {
        [$owner, $company] = $this->createOwnerWithCompany();
        Sanctum::actingAs($owner);

        $base = "/api/company-workspace/{$company->id}";
        $this->postJson("{$base}/price-lists", ['name' => 'List A'])->assertCreated();
        $this->postJson("{$base}/price-lists", ['name' => 'List B'])->assertCreated();

        $this->getJson("{$base}/price-lists")->assertOk()->assertJsonPath('ok', true);
        $items = $this->getJson("{$base}/price-lists")->json('data.items');
        $this->assertIsArray($items);
        $this->assertGreaterThanOrEqual(2, count($items));
    }

    public function test_partner_project_head_can_create_one_own_active_price_list(): void
    {
        [$owner, $company, $ownerCp] = $this->createOwnerWithCompany();
        $partner = User::factory()->create();
        $partnerCp = $this->createPartnerCounterparty($company, $partner);
        $this->createProjectWithPartnerHead($company, $partnerCp);

        Sanctum::actingAs($partner);
        $base = "/api/company-workspace/{$company->id}";
        $this->postJson("{$base}/price-lists", ['name' => 'Partner PL'])->assertCreated();
    }

    public function test_partner_project_head_cannot_create_second_active_own_price_list(): void
    {
        [$owner, $company, $ownerCp] = $this->createOwnerWithCompany();
        $partner = User::factory()->create();
        $partnerCp = $this->createPartnerCounterparty($company, $partner);
        $this->createProjectWithPartnerHead($company, $partnerCp);

        Sanctum::actingAs($partner);
        $base = "/api/company-workspace/{$company->id}";
        $this->postJson("{$base}/price-lists", ['name' => 'First'])->assertCreated();
        // Второй активный свой прайс: assertCanCreatePriceList даёт 403 (can_create_company_price_list=false),
        // до ветки 422 в контроллере выполнение не доходит.
        $this->postJson("{$base}/price-lists", ['name' => 'Second'])
            ->assertForbidden();
    }

    public function test_partner_who_is_not_project_head_anywhere_cannot_create_price_list(): void
    {
        [$owner, $company, $ownerCp] = $this->createOwnerWithCompany();
        $partner = User::factory()->create();
        $partnerCp = $this->createPartnerCounterparty($company, $partner);
        $project = $this->createProjectWithOwnerHead($company, $ownerCp);
        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $this->postJson("{$base}/projects/{$project->id}/participants", [
            'counterparty_id' => $partnerCp->id,
            'role' => ProjectRoleCode::PARTNER->value,
        ])->assertCreated();

        Sanctum::actingAs($partner);
        $this->postJson("{$base}/price-lists", ['name' => 'Should fail'])
            ->assertForbidden();
    }

    public function test_partner_cannot_patch_others_price_list(): void
    {
        [$owner, $company] = $this->createOwnerWithCompany();
        $partner = User::factory()->create();
        $this->createPartnerCounterparty($company, $partner);

        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $ownerListId = (int) $this->postJson("{$base}/price-lists", ['name' => 'Owner list'])
            ->assertCreated()
            ->json('data.price_list.id');

        Sanctum::actingAs($partner);
        $this->patchJson("{$base}/price-lists/{$ownerListId}", ['name' => 'Hacked'])
            ->assertForbidden();
    }

    public function test_owner_can_attach_any_active_company_price_list_to_project(): void
    {
        [$owner, $company, $ownerCp] = $this->createOwnerWithCompany();
        $project = $this->createProjectWithOwnerHead($company, $ownerCp);

        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $idA = (int) $this->postJson("{$base}/price-lists", ['name' => 'PL A'])->json('data.price_list.id');
        $idB = (int) $this->postJson("{$base}/price-lists", ['name' => 'PL B'])->json('data.price_list.id');

        $first = $this->postJson("{$base}/projects/{$project->id}/price-lists/attach", [
            'price_list_ids' => [$idA, $idB],
        ])->assertOk();
        $this->assertEqualsCanonicalizing([$idA, $idB], $first->json('data.attached_price_list_ids'));

        $second = $this->postJson("{$base}/projects/{$project->id}/price-lists/attach", [
            'price_list_ids' => [$idA, $idB],
        ])->assertOk();
        $this->assertSame([], $second->json('data.attached_price_list_ids'));
    }

    public function test_partner_project_head_can_attach_only_own_price_list_to_project(): void
    {
        [$owner, $company, $ownerCp] = $this->createOwnerWithCompany();
        $partner = User::factory()->create();
        $partnerCp = $this->createPartnerCounterparty($company, $partner);
        $partnerProject = $this->createProjectWithPartnerHead($company, $partnerCp);

        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $ownerListId = (int) $this->postJson("{$base}/price-lists", ['name' => 'Owner PL'])->json('data.price_list.id');

        Sanctum::actingAs($partner);
        $partnerListId = (int) $this->postJson("{$base}/price-lists", ['name' => 'Partner PL'])->json('data.price_list.id');

        $this->postJson("{$base}/projects/{$partnerProject->id}/price-lists/attach", [
            'price_list_ids' => [$ownerListId],
        ])->assertForbidden();

        $this->postJson("{$base}/projects/{$partnerProject->id}/price-lists/attach", [
            'price_list_ids' => [$partnerListId],
        ])->assertOk()->assertJsonPath('data.attached_price_list_ids', [$partnerListId]);
    }

    public function test_position_cannot_be_created_without_unit_id(): void
    {
        [$owner, $company] = $this->createOwnerWithCompany();
        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $listId = (int) $this->postJson("{$base}/price-lists", ['name' => 'L'])->json('data.price_list.id');
        $groupId = (int) $this->postJson("{$base}/price-lists/{$listId}/groups", ['name' => 'G'])
            ->json('data.group.id');

        $response = $this->postJson("{$base}/price-lists/{$listId}/groups/{$groupId}/positions", [
            'service_name' => 'Work',
            'recipient_unit_price' => '10.00',
            'customer_unit_price' => '12.00',
        ])->assertStatus(422);
        $this->assertArrayHasKey('unit_id', $response->json('error.fields') ?? []);
    }

    public function test_position_cannot_be_created_with_non_positive_recipient_unit_price(): void
    {
        [$owner, $company] = $this->createOwnerWithCompany();
        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $listId = (int) $this->postJson("{$base}/price-lists", ['name' => 'L'])->json('data.price_list.id');
        $groupId = (int) $this->postJson("{$base}/price-lists/{$listId}/groups", ['name' => 'G'])
            ->json('data.group.id');
        $unitId = $this->systemUnitId();

        $this->postJson("{$base}/price-lists/{$listId}/groups/{$groupId}/positions", [
            'service_name' => 'Work',
            'unit_id' => $unitId,
            'recipient_unit_price' => '0',
            'customer_unit_price' => '10.00',
        ])->assertStatus(422)->assertJsonPath('error.message', 'recipient_unit_price must be greater than 0.');
    }

    public function test_position_rejects_non_numeric_recipient_unit_price(): void
    {
        [$owner, $company] = $this->createOwnerWithCompany();
        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $listId = (int) $this->postJson("{$base}/price-lists", ['name' => 'L'])->json('data.price_list.id');
        $groupId = (int) $this->postJson("{$base}/price-lists/{$listId}/groups", ['name' => 'G'])
            ->json('data.group.id');
        $unitId = $this->systemUnitId();

        $this->postJson("{$base}/price-lists/{$listId}/groups/{$groupId}/positions", [
            'service_name' => 'Work',
            'unit_id' => $unitId,
            'recipient_unit_price' => 'not-a-number',
            'customer_unit_price' => '10.00',
        ])->assertStatus(422)->assertJsonPath('error.message', 'recipient_unit_price must be greater than 0.');
    }

    public function test_available_price_lists_for_project_contains_company_lists(): void
    {
        [$owner, $company, $ownerCp] = $this->createOwnerWithCompany();
        $project = $this->createProjectWithOwnerHead($company, $ownerCp);

        Sanctum::actingAs($owner);
        $base = "/api/company-workspace/{$company->id}";
        $idA = (int) $this->postJson("{$base}/price-lists", ['name' => 'PL Av A'])->json('data.price_list.id');
        $idB = (int) $this->postJson("{$base}/price-lists", ['name' => 'PL Av B'])->json('data.price_list.id');

        $res = $this->getJson("{$base}/projects/{$project->id}/price-lists/available")->assertOk();
        $ids = array_column($res->json('data.price_lists') ?? [], 'id');
        self::assertContains($idA, $ids);
        self::assertContains($idB, $ids);
    }
}
