<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\User;
use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Enums\OperationType;
use App\Modules\Operations\Enums\TransferTargetType;
use App\Modules\Operations\Models\Operation;
use App\Modules\Operations\Models\TransferOperation;
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
 * ТЗ-10C: привязка перевода к отчёту по operation_number (TRF-{id}).
 */
final class ReportTransferLinksCompanyWorkspaceTest extends TestCase
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

    public function test_attach_list_detach_transfer_link_on_report(): void
    {
        $headUser = User::factory()->create();
        $partnerUser = User::factory()->create();
        $customerUser = User::factory()->create();

        $company = Company::query()->create([
            'name' => 'Co Report Links',
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
            'name' => 'P1',
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
            'name' => 'EI',
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

        $op = Operation::query()->create([
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppHead->id,
            'operation_type' => OperationType::TRANSFER,
            'operation_status' => OperationStatus::CREATED,
        ]);
        $transfer = TransferOperation::query()->create([
            'operation_id' => $op->id,
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppHead->id,
            'sender_project_participant_id' => $ppHead->id,
            'receiver_project_participant_id' => $ppPartner->id,
            'transfer_target_type' => TransferTargetType::PERSONAL_BALANCE,
            'amount' => '10.00',
            'comment' => null,
            'operation_status' => OperationStatus::CREATED,
            'wallets_applied_at' => null,
        ]);
        $transfer->update(['operation_number' => 'TRF-'.$transfer->id]);

        $base = "/api/company-workspace/{$company->id}";
        $opDate = Carbon::now()->format('Y-m-d');

        Sanctum::actingAs($headUser);
        $create = $this->postJson("{$base}/projects/{$project->id}/operations/reports", [
            'expense_item_id' => $expenseItem->id,
            'recipient_counterparty_id' => $cpPartner->id,
            'operation_date' => $opDate,
            'comment' => null,
            'lines' => [[
                'source_type' => 'CUSTOM',
                'price_list_id' => null,
                'price_list_group_id' => null,
                'price_list_position_id' => null,
                'name' => 'Work',
                'unit_id' => null,
                'unit_name' => 'усл.',
                'unit_short_name' => 'усл.',
                'quantity' => '1',
                'recipient_unit_price' => '10.00',
                'customer_unit_price' => '50.00',
                'recipient_total' => '10.00',
                'customer_total' => '50.00',
            ]],
        ]);
        $create->assertCreated();
        $reportId = (int) $create->json('data.report.id');

        $attach = $this->postJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/transfer-links", [
            'operation_number' => 'TRF-'.$transfer->id,
        ]);
        $attach->assertStatus(201)->assertJsonPath('ok', true);
        $linkId = (int) $attach->json('data.link.id');
        self::assertGreaterThan(0, $linkId);

        $list = $this->getJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/transfer-links");
        $list->assertOk();
        $items = $list->json('data.items');
        self::assertCount(1, $items);
        self::assertSame($transfer->id, (int) ($items[0]['transfer']['id'] ?? 0));

        $detach = $this->deleteJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/transfer-links/{$linkId}");
        $detach->assertOk();

        $list2 = $this->getJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/transfer-links");
        $list2->assertOk();
        self::assertSame([], $list2->json('data.items'));
    }

    public function test_attach_same_transfer_twice_returns_422(): void
    {
        $headUser = User::factory()->create();
        $partnerUser = User::factory()->create();
        $customerUser = User::factory()->create();

        $company = Company::query()->create([
            'name' => 'Co Rpt Dup',
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
            'name' => 'P3',
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
            'name' => 'EI3',
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

        $op = Operation::query()->create([
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppHead->id,
            'operation_type' => OperationType::TRANSFER,
            'operation_status' => OperationStatus::CREATED,
        ]);
        $transfer = TransferOperation::query()->create([
            'operation_id' => $op->id,
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppHead->id,
            'sender_project_participant_id' => $ppHead->id,
            'receiver_project_participant_id' => $ppPartner->id,
            'transfer_target_type' => TransferTargetType::PERSONAL_BALANCE,
            'amount' => '2.00',
            'comment' => null,
            'operation_status' => OperationStatus::CREATED,
            'wallets_applied_at' => null,
        ]);
        $transfer->update(['operation_number' => 'TRF-'.$transfer->id]);

        $base = "/api/company-workspace/{$company->id}";
        $opDate = Carbon::now()->format('Y-m-d');

        Sanctum::actingAs($headUser);
        $create = $this->postJson("{$base}/projects/{$project->id}/operations/reports", [
            'expense_item_id' => $expenseItem->id,
            'recipient_counterparty_id' => $cpPartner->id,
            'operation_date' => $opDate,
            'lines' => [[
                'source_type' => 'CUSTOM',
                'name' => 'Y',
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

        $this->postJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/transfer-links", [
            'operation_number' => 'TRF-'.$transfer->id,
        ])->assertStatus(201);

        $dup = $this->postJson("{$base}/projects/{$project->id}/operations/reports/{$reportId}/transfer-links", [
            'operation_number' => 'TRF-'.$transfer->id,
        ]);
        $dup->assertStatus(422);
    }
}
