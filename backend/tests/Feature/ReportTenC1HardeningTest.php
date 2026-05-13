<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\User;
use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Operations\Models\ReportWalletDelta;
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
 * ТЗ-10C.1: lifecycle + payload + attach guard + list search + customer approve (дубликат attach → {@see ReportTransferLinksCompanyWorkspaceTest}).
 */
final class ReportTenC1HardeningTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        if (! extension_loaded('pdo_sqlite')) {
            $this->markTestSkipped('pdo_sqlite required');
        }
        parent::setUp();
        $this->seed(CompanyRoleSeeder::class);
        $this->seed(ProjectRoleSeeder::class);
    }

    public function test_customer_personal_show_excludes_internal_amount_fields(): void
    {
        $ctx = $this->seedHeadPartnerCustomerProjectWithExpense();
        $base = $ctx['base'];
        $project = $ctx['project'];
        $headUser = $ctx['headUser'];
        $customerUser = $ctx['customerUser'];
        $expenseItem = $ctx['expenseItem'];
        $cpPartner = $ctx['cpPartner'];

        Sanctum::actingAs($headUser);
        $opDate = Carbon::now()->format('Y-m-d');
        $create = $this->postJson("{$base}/projects/{$project->id}/operations/reports", [
            'expense_item_id' => $expenseItem->id,
            'recipient_counterparty_id' => $cpPartner->id,
            'operation_date' => $opDate,
            'lines' => [[
                'source_type' => 'CUSTOM',
                'name' => 'L',
                'unit_name' => 'u',
                'unit_short_name' => 'u',
                'quantity' => '1',
                'recipient_unit_price' => '1.00',
                'customer_unit_price' => '5.00',
                'recipient_total' => '1.00',
                'customer_total' => '5.00',
            ]],
        ]);
        $create->assertCreated();
        $reportId = (int) $create->json('data.report.id');
        $this->postJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/submit")->assertOk();

        Sanctum::actingAs($customerUser);
        $show = $this->getJson("/api/personal-workspace/projects/{$project->id}/operations/reports/{$reportId}");
        $show->assertOk()->assertJsonPath('data.viewer_context', 'customer');
        $report = $show->json('data.report');
        self::assertIsArray($report);
        foreach (['profit_amount', 'markup_amount', 'recipient_amount', 'customer_base_amount', 'expense_item_id', 'transfer_links'] as $k) {
            self::assertArrayNotHasKey($k, $report, "customer payload must not contain {$k}");
        }
    }

    public function test_second_order_recipient_show_omits_customer_totals_and_expense_item(): void
    {
        $headUser = User::factory()->create();
        $partnerUser = User::factory()->create();
        $customerUser = User::factory()->create();
        $supplierUser = User::factory()->create();

        $company = Company::query()->create([
            'name' => 'Co 2nd',
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
        $cpSupplier = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $supplierUser->id,
            'company_role_code' => CompanyRoleCode::SUPPLIER->value,
            'is_active' => true,
        ]);

        $project = Project::query()->create([
            'company_id' => $company->id,
            'name' => 'P2nd',
            'progress_percent' => 0,
            'is_active' => true,
        ]);

        foreach ([[$cpHead, ProjectRoleCode::PROJECT_HEAD], [$cpPartner, ProjectRoleCode::PARTNER], [$cpCustomer, ProjectRoleCode::CUSTOMER]] as [$cp, $role]) {
            $pp = ProjectParticipant::query()->create([
                'project_id' => $project->id,
                'counterparty_id' => $cp->id,
                'project_role_code' => $role->value,
                'level' => 'first',
                'is_active' => true,
            ]);
            app(WalletFactoryService::class)->createForParticipant($pp);
        }

        $expenseItem = ProjectExpenseItem::query()->create([
            'project_id' => $project->id,
            'name' => 'EI2',
            'markup_enabled' => false,
            'markup_percent' => null,
            'is_active' => true,
            'created_by_user_id' => $headUser->id,
        ]);
        foreach ([$cpHead, $cpPartner] as $cp) {
            ProjectExpenseItemProfitShare::query()->create([
                'expense_item_id' => $expenseItem->id,
                'counterparty_id' => $cp->id,
                'percent' => '50.00',
            ]);
        }

        $base = "/api/company-workspace/{$company->id}";
        $opDate = Carbon::now()->format('Y-m-d');

        Sanctum::actingAs($headUser);
        $create = $this->postJson("{$base}/projects/{$project->id}/operations/reports", [
            'expense_item_id' => $expenseItem->id,
            'recipient_counterparty_id' => $cpSupplier->id,
            'operation_date' => $opDate,
            'lines' => [[
                'source_type' => 'CUSTOM',
                'name' => 'Ext',
                'unit_name' => 'u',
                'unit_short_name' => 'u',
                'quantity' => '1',
                'recipient_unit_price' => '2.00',
                'customer_unit_price' => '9.00',
                'recipient_total' => '2.00',
                'customer_total' => '9.00',
            ]],
        ]);
        $create->assertCreated();
        $reportId = (int) $create->json('data.report.id');

        Sanctum::actingAs($supplierUser);
        $show = $this->getJson("/api/personal-workspace/projects/{$project->id}/operations/reports/{$reportId}");
        $show->assertOk()->assertJsonPath('data.viewer_context', 'second_order_recipient');
        $report = $show->json('data.report');
        foreach (['customer_total_amount', 'customer_base_amount', 'markup_amount', 'profit_amount', 'expense_item_id'] as $k) {
            self::assertArrayNotHasKey($k, $report);
        }
        $lines = $report['lines'] ?? [];
        self::assertIsArray($lines);
        self::assertNotEmpty($lines);
        self::assertArrayNotHasKey('customer_unit_price', $lines[0]);
        self::assertArrayNotHasKey('customer_total', $lines[0]);
    }

    public function test_waiting_24_hours_report_not_in_pending_count(): void
    {
        $ctx = $this->seedHeadPartnerCustomerProjectWithExpense();
        $base = $ctx['base'];
        $project = $ctx['project'];
        $headUser = $ctx['headUser'];
        $customerUser = $ctx['customerUser'];
        $expenseItem = $ctx['expenseItem'];
        $cpPartner = $ctx['cpPartner'];
        $company = $ctx['company'];

        Sanctum::actingAs($headUser);
        $opDate = Carbon::now()->format('Y-m-d');
        $create = $this->postJson("{$base}/projects/{$project->id}/operations/reports", [
            'expense_item_id' => $expenseItem->id,
            'recipient_counterparty_id' => $cpPartner->id,
            'operation_date' => $opDate,
            'lines' => [[
                'source_type' => 'CUSTOM',
                'name' => 'W',
                'unit_name' => 'u',
                'unit_short_name' => 'u',
                'quantity' => '1',
                'recipient_unit_price' => '1.00',
                'customer_unit_price' => '4.00',
                'recipient_total' => '1.00',
                'customer_total' => '4.00',
            ]],
        ]);
        $reportId = (int) $create->json('data.report.id');
        $this->postJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/submit")->assertOk();

        Sanctum::actingAs($customerUser);
        $this->postJson("/api/personal-workspace/projects/{$project->id}/operations/reports/{$reportId}/approve-customer")
            ->assertOk();

        Sanctum::actingAs($headUser);
        $pending = $this->getJson("/api/company-workspace/{$company->id}/operations/reports/pending-count");
        $pending->assertOk();
        self::assertSame(0, (int) $pending->json('data.pending_action_count'));
    }

    public function test_customer_approve_via_personal_moves_report_to_waiting_24_hours(): void
    {
        $ctx = $this->seedHeadPartnerCustomerProjectWithExpense();
        $base = $ctx['base'];
        $project = $ctx['project'];
        $headUser = $ctx['headUser'];
        $customerUser = $ctx['customerUser'];
        $expenseItem = $ctx['expenseItem'];
        $cpPartner = $ctx['cpPartner'];

        Sanctum::actingAs($headUser);
        $opDate = Carbon::now()->format('Y-m-d');
        $create = $this->postJson("{$base}/projects/{$project->id}/operations/reports", [
            'expense_item_id' => $expenseItem->id,
            'recipient_counterparty_id' => $cpPartner->id,
            'operation_date' => $opDate,
            'lines' => [[
                'source_type' => 'CUSTOM',
                'name' => 'Appr',
                'unit_name' => 'u',
                'unit_short_name' => 'u',
                'quantity' => '1',
                'recipient_unit_price' => '1.00',
                'customer_unit_price' => '4.00',
                'recipient_total' => '1.00',
                'customer_total' => '4.00',
            ]],
        ]);
        $create->assertCreated();
        $reportId = (int) $create->json('data.report.id');
        $this->postJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/submit")->assertOk();

        Sanctum::actingAs($customerUser);
        $this->postJson("/api/personal-workspace/projects/{$project->id}/operations/reports/{$reportId}/approve-customer")
            ->assertOk();

        $report = ReportOperation::query()->findOrFail($reportId);
        self::assertSame(OperationStatus::WAITING_24_HOURS->value, $report->operation_status->value);
    }

    public function test_customer_reject_via_personal_reverts_wallet_deltas(): void
    {
        $ctx = $this->seedHeadPartnerCustomerProjectWithExpense();
        $base = $ctx['base'];
        $project = $ctx['project'];
        $headUser = $ctx['headUser'];
        $partnerUser = $ctx['partnerUser'];
        $customerUser = $ctx['customerUser'];
        $expenseItem = $ctx['expenseItem'];
        $cpHead = $ctx['cpHead'];

        Sanctum::actingAs($partnerUser);
        $opDate = Carbon::now()->format('Y-m-d');
        $create = $this->postJson("{$base}/projects/{$project->id}/operations/reports", [
            'expense_item_id' => $expenseItem->id,
            'recipient_counterparty_id' => $cpHead->id,
            'operation_date' => $opDate,
            'lines' => [[
                'source_type' => 'CUSTOM',
                'name' => 'Rj',
                'unit_name' => 'u',
                'unit_short_name' => 'u',
                'quantity' => '1',
                'recipient_unit_price' => '1.00',
                'customer_unit_price' => '6.00',
                'recipient_total' => '1.00',
                'customer_total' => '6.00',
            ]],
        ]);
        $create->assertCreated();
        $reportId = (int) $create->json('data.report.id');
        $this->postJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/submit")->assertOk();

        Sanctum::actingAs($headUser);
        $this->postJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/approve-project-head")->assertOk();

        self::assertGreaterThan(0, ReportWalletDelta::query()->where('report_operation_id', $reportId)->whereNull('reverted_at')->count());

        Sanctum::actingAs($customerUser);
        $this->postJson("/api/personal-workspace/projects/{$project->id}/operations/reports/{$reportId}/reject-customer", [
            'comment' => 'no thanks',
        ])->assertOk();

        $report = ReportOperation::query()->findOrFail($reportId);
        self::assertSame(OperationStatus::PROJECT_HEAD_APPROVAL->value, $report->operation_status->value);
        self::assertNull($report->wallets_applied_at);
        self::assertNotNull($report->wallets_reverted_at);
        self::assertSame(
            0,
            ReportWalletDelta::query()->where('report_operation_id', $reportId)->whereNull('reverted_at')->count(),
        );
    }

    public function test_attach_transfer_from_other_project_returns_422(): void
    {
        $ctx = $this->seedHeadPartnerCustomerProjectWithExpense();
        $base = $ctx['base'];
        $project = $ctx['project'];
        $headUser = $ctx['headUser'];
        $company = $ctx['company'];
        $cpPartner = $ctx['cpPartner'];
        $expenseItem = $ctx['expenseItem'];
        $ppHead = $ctx['ppHead'];

        $project2 = Project::query()->create([
            'company_id' => $company->id,
            'name' => 'P-other',
            'progress_percent' => 0,
            'is_active' => true,
        ]);

        $transfer = \App\Modules\Operations\Models\TransferOperation::query()->create([
            'operation_id' => \App\Modules\Operations\Models\Operation::query()->create([
                'project_id' => $project2->id,
                'initiator_project_participant_id' => $ppHead->id,
                'operation_type' => \App\Modules\Operations\Enums\OperationType::TRANSFER,
                'operation_status' => OperationStatus::CREATED,
            ])->id,
            'project_id' => $project2->id,
            'initiator_project_participant_id' => $ppHead->id,
            'sender_project_participant_id' => $ppHead->id,
            'receiver_project_participant_id' => $ctx['ppPartner']->id,
            'transfer_target_type' => \App\Modules\Operations\Enums\TransferTargetType::PERSONAL_BALANCE,
            'amount' => '1.00',
            'comment' => null,
            'operation_status' => OperationStatus::CREATED,
        ]);
        $transfer->update(['operation_number' => 'TRF-'.$transfer->id]);

        Sanctum::actingAs($headUser);
        $opDate = Carbon::now()->format('Y-m-d');
        $create = $this->postJson("{$base}/projects/{$project->id}/operations/reports", [
            'expense_item_id' => $expenseItem->id,
            'recipient_counterparty_id' => $cpPartner->id,
            'operation_date' => $opDate,
            'lines' => [[
                'source_type' => 'CUSTOM',
                'name' => 'X',
                'unit_name' => 'u',
                'unit_short_name' => 'u',
                'quantity' => '1',
                'recipient_unit_price' => '1.00',
                'customer_unit_price' => '3.00',
                'recipient_total' => '1.00',
                'customer_total' => '3.00',
            ]],
        ]);
        $reportId = (int) $create->json('data.report.id');

        $this->postJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/transfer-links", [
            'operation_number' => 'TRF-'.$transfer->id,
        ])->assertStatus(422);
    }

    public function test_transfer_list_search_by_operation_number(): void
    {
        $ctx = $this->seedHeadPartnerCustomerProjectWithExpense();
        $base = $ctx['base'];
        $project = $ctx['project'];
        $headUser = $ctx['headUser'];
        $ppHead = $ctx['ppHead'];
        $ppPartner = $ctx['ppPartner'];

        $op = \App\Modules\Operations\Models\Operation::query()->create([
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppHead->id,
            'operation_type' => \App\Modules\Operations\Enums\OperationType::TRANSFER,
            'operation_status' => OperationStatus::CREATED,
        ]);
        $transfer = \App\Modules\Operations\Models\TransferOperation::query()->create([
            'operation_id' => $op->id,
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppHead->id,
            'sender_project_participant_id' => $ppHead->id,
            'receiver_project_participant_id' => $ppPartner->id,
            'transfer_target_type' => \App\Modules\Operations\Enums\TransferTargetType::PERSONAL_BALANCE,
            'amount' => '7.50',
            'comment' => null,
            'operation_status' => OperationStatus::CREATED,
        ]);
        $transfer->update(['operation_number' => 'TRF-'.$transfer->id]);

        Sanctum::actingAs($headUser);
        $num = 'TRF-'.$transfer->id;
        $res = $this->getJson("{$base}/projects/{$project->id}/operations/transfers?search=".urlencode($num).'&page=1&per_page=20');
        $res->assertOk();
        $items = $res->json('data.items');
        self::assertIsArray($items);
        self::assertGreaterThanOrEqual(1, count($items));
        self::assertSame($num, $items[0]['operation_number'] ?? null);
    }

    /**
     * @return array{
     *   company: Company,
     *   project: Project,
     *   headUser: User,
     *   partnerUser: User,
     *   customerUser: User,
     *   cpHead: Counterparty,
     *   cpPartner: Counterparty,
     *   cpCustomer: Counterparty,
     *   ppHead: ProjectParticipant,
     *   ppPartner: ProjectParticipant,
     *   expenseItem: ProjectExpenseItem,
     *   base: string,
     * }
     */
    private function seedHeadPartnerCustomerProjectWithExpense(): array
    {
        $headUser = User::factory()->create();
        $partnerUser = User::factory()->create();
        $customerUser = User::factory()->create();

        $company = Company::query()->create([
            'name' => 'Co Hardening',
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
            'name' => 'P-H',
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
            'name' => 'EI-H',
            'markup_enabled' => false,
            'markup_percent' => null,
            'is_active' => true,
            'created_by_user_id' => $headUser->id,
        ]);
        foreach ([$cpHead, $cpPartner] as $cp) {
            ProjectExpenseItemProfitShare::query()->create([
                'expense_item_id' => $expenseItem->id,
                'counterparty_id' => $cp->id,
                'percent' => '50.00',
            ]);
        }

        return [
            'company' => $company,
            'project' => $project,
            'headUser' => $headUser,
            'partnerUser' => $partnerUser,
            'customerUser' => $customerUser,
            'cpHead' => $cpHead,
            'cpPartner' => $cpPartner,
            'cpCustomer' => $cpCustomer,
            'ppHead' => $ppHead,
            'ppPartner' => $ppPartner,
            'expenseItem' => $expenseItem,
            'base' => "/api/company-workspace/{$company->id}",
        ];
    }
}
