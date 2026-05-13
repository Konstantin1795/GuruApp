<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\User;
use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectExpenseItem;
use App\Modules\Projects\Models\ProjectExpenseItemProfitShare;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\WalletFactoryService;
use Carbon\Carbon;
use Database\Seeders\CompanyRoleSeeder;
use Database\Seeders\ProjectRoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * ТЗ-10C.1: personal-workspace REPORT list/show + customer approve; урезанный payload для заказчика.
 */
final class ReportPersonalWorkspaceApiTest extends TestCase
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

    public function test_customer_personal_show_omits_internal_amounts_and_transfer_links(): void
    {
        $headUser = User::factory()->create();
        $partnerUser = User::factory()->create();
        $customerUser = User::factory()->create();

        $company = Company::query()->create([
            'name' => 'Co Rpt PW API',
            'created_by_user_id' => $headUser->id,
            'is_active' => true,
        ]);

        $cpHead = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $headUser->id,
            'company_role_code' => CompanyRoleCode::OWNER->value,
            'is_active' => true,
        ]);
        $cpPartner = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $partnerUser->id,
            'company_role_code' => CompanyRoleCode::PARTNER->value,
            'is_active' => true,
        ]);
        $cpCustomer = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $customerUser->id,
            'company_role_code' => CompanyRoleCode::CUSTOMER->value,
            'is_active' => true,
        ]);

        $project = Project::query()->create([
            'company_id' => $company->id,
            'name' => 'P-PW-API',
            'progress_percent' => 0,
            'is_active' => true,
        ]);

        $ppHead = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpHead->id,
            'project_role_code' => ProjectRoleCode::PROJECT_HEAD->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $ppPartner = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpPartner->id,
            'project_role_code' => ProjectRoleCode::PARTNER->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $ppCustomer = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpCustomer->id,
            'project_role_code' => ProjectRoleCode::CUSTOMER->value,
            'level' => 'first',
            'is_active' => true,
        ]);

        $wallets = app(WalletFactoryService::class);
        $wallets->createForParticipant($ppHead);
        $wallets->createForParticipant($ppPartner);
        $wallets->createForParticipant($ppCustomer);

        $expenseItem = ProjectExpenseItem::query()->create([
            'project_id' => $project->id,
            'name' => 'EI-PW-API',
            'markup_enabled' => false,
            'markup_percent' => null,
            'is_active' => true,
            'created_by_user_id' => $headUser->id,
        ]);
        ProjectExpenseItemProfitShare::query()->create([
            'expense_item_id' => $expenseItem->id,
            'counterparty_id' => $cpHead->id,
            'percent' => '50.00',
        ]);
        ProjectExpenseItemProfitShare::query()->create([
            'expense_item_id' => $expenseItem->id,
            'counterparty_id' => $cpPartner->id,
            'percent' => '50.00',
        ]);

        $base = "/api/company-workspace/{$company->id}";
        $opDate = Carbon::now()->format('Y-m-d');

        Sanctum::actingAs($headUser);
        $create = $this->postJson("{$base}/projects/{$project->id}/operations/reports", [
            'expense_item_id' => $expenseItem->id,
            'recipient_counterparty_id' => $cpPartner->id,
            'operation_date' => $opDate,
            'lines' => [[
                'source_type' => 'CUSTOM',
                'name' => 'Job',
                'unit_name' => 'u',
                'unit_short_name' => 'u',
                'quantity' => '1',
                'recipient_unit_price' => '2.00',
                'customer_unit_price' => '8.00',
                'recipient_total' => '2.00',
                'customer_total' => '8.00',
            ]],
        ]);
        $create->assertCreated();
        $reportId = (int) $create->json('data.report.id');

        $this->postJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/submit")->assertOk();

        Sanctum::actingAs($customerUser);
        $list = $this->getJson("/api/personal-workspace/projects/{$project->id}/operations/reports");
        $list->assertOk();
        $reports = $list->json('data.reports');
        self::assertIsArray($reports);
        self::assertGreaterThanOrEqual(1, count($reports));

        $show = $this->getJson("/api/personal-workspace/projects/{$project->id}/operations/reports/{$reportId}");
        $show->assertOk();
        $show->assertJsonPath('data.viewer_context', 'customer');
        $report = $show->json('data.report');
        self::assertIsArray($report);
        self::assertArrayNotHasKey('profit_amount', $report);
        self::assertArrayNotHasKey('transfer_links', $report);
        self::assertArrayNotHasKey('recipient_amount', $report);
        self::assertSame(OperationStatus::CUSTOMER_APPROVAL->value, $report['operation_status']);

        $this->postJson("/api/personal-workspace/projects/{$project->id}/operations/reports/{$reportId}/approve-customer")
            ->assertOk()
            ->assertJsonPath('data.report.operation_status', OperationStatus::WAITING_24_HOURS->value);
    }
}
