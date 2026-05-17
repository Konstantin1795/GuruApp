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
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Operations\Models\ReportWalletDelta;
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

final class CompanyDashboardAnalyticsTest extends TestCase
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

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_owner_dashboard_sees_company_wide_earnings_and_income(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        $applied = Carbon::parse('2026-05-10 10:00:00', 'UTC');

        $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppPartner']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: $applied,
            deltaCents: 10_000,
        );
        $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppHead']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpHead']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: $applied,
            deltaCents: 5_000,
        );

        Sanctum::actingAs($ctx['ownerUser']);
        $res = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics");
        $res->assertOk()->assertJsonPath('ok', true);
        self::assertSame('owner', $res->json('data.matrix_role'));
        self::assertSame('150.00', $res->json('data.income_total'));
        self::assertSame('150.00', $res->json('data.debt_total'));
        self::assertSame('0.00', $res->json('data.overpayment_total'));
    }

    public function test_partner_income_from_transfer_to_personal_balance(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        $applied = Carbon::parse('2026-05-08 08:00:00', 'UTC');
        $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppPartner']->id,
            amount: '40.00',
            appliedAt: $applied,
        );

        Sanctum::actingAs($ctx['partnerUser']);
        $res = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics");
        $res->assertOk();
        self::assertSame('40.00', $res->json('data.income_total'));
    }

    public function test_partner_debt_from_report_earned_without_transfer(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        $applied = Carbon::parse('2026-05-01 08:00:00', 'UTC');
        $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppPartner']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: $applied,
            deltaCents: 12_500,
        );

        Sanctum::actingAs($ctx['partnerUser']);
        $res = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics");
        $res->assertOk();
        self::assertSame('0.00', $res->json('data.income_total'));
        self::assertSame('125.00', $res->json('data.debt_total'));
        self::assertSame('0.00', $res->json('data.overpayment_total'));
    }

    public function test_partner_second_level_participant_earnings_counted(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();

        ProjectParticipant::query()
            ->where('id', $ctx['ppPartner']->id)
            ->update(['level' => 'second']);

        $applied = Carbon::parse('2026-05-02 08:00:00', 'UTC');
        $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppPartner']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: $applied,
            deltaCents: 3_300,
        );

        Sanctum::actingAs($ctx['partnerUser']);
        $res = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics");
        $res->assertOk();
        self::assertSame('33.00', $res->json('data.debt_total'));
    }

    public function test_overpayment_when_received_exceeds_earned(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppPartner']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: Carbon::parse('2026-05-03 08:00:00', 'UTC'),
            deltaCents: 5_000,
        );
        $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppPartner']->id,
            amount: '80.00',
            appliedAt: Carbon::parse('2026-05-04 08:00:00', 'UTC'),
        );

        Sanctum::actingAs($ctx['partnerUser']);
        $res = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics");
        $res->assertOk();
        self::assertSame('0.00', $res->json('data.debt_total'));
        self::assertSame('30.00', $res->json('data.overpayment_total'));
    }

    public function test_owner_debt_and_overpayment_do_not_net_across_participants(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppPartner']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: Carbon::parse('2026-05-02 08:00:00', 'UTC'),
            deltaCents: 10_000,
        );
        $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppHead']->id,
            amount: '50.00',
            appliedAt: Carbon::parse('2026-05-03 08:00:00', 'UTC'),
        );

        Sanctum::actingAs($ctx['ownerUser']);
        $res = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics");
        $res->assertOk();
        self::assertSame('100.00', $res->json('data.debt_total'));
        self::assertSame('50.00', $res->json('data.overpayment_total'));
    }

    public function test_report_and_transfer_same_participant_balance_without_transfer_links(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppPartner']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: Carbon::parse('2026-05-04 08:00:00', 'UTC'),
            deltaCents: 50_000,
        );
        $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppPartner']->id,
            amount: '500.00',
            appliedAt: Carbon::parse('2026-05-05 08:00:00', 'UTC'),
        );

        Sanctum::actingAs($ctx['ownerUser']);
        $owner = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics");
        $owner->assertOk();
        self::assertSame('0.00', $owner->json('data.debt_total'));
        self::assertSame('0.00', $owner->json('data.overpayment_total'));

        Sanctum::actingAs($ctx['partnerUser']);
        $partner = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics");
        $partner->assertOk();
        self::assertSame('0.00', $partner->json('data.debt_total'));
        self::assertSame('0.00', $partner->json('data.overpayment_total'));
    }

    public function test_partner_two_projects_debt_and_overpayment_independent(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();

        $p2 = Project::query()->create([
            'company_id' => $ctx['company']->id,
            'name' => 'P-second',
            'progress_percent' => 0,
            'is_active' => true,
        ]);
        $ppPartnerP2 = ProjectParticipant::query()->create([
            'project_id' => $p2->id,
            'counterparty_id' => $ctx['cpPartner']->id,
            'project_role_code' => ProjectRoleCode::PARTNER->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $ppCustomerP2 = ProjectParticipant::query()->create([
            'project_id' => $p2->id,
            'counterparty_id' => $ctx['cpCustomer']->id,
            'project_role_code' => ProjectRoleCode::CUSTOMER->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $wallets = app(WalletFactoryService::class);
        $wallets->createForParticipant($ppPartnerP2);
        $wallets->createForParticipant($ppCustomerP2);

        $ei2 = ProjectExpenseItem::query()->create([
            'project_id' => $p2->id,
            'name' => 'EI-p2',
            'markup_enabled' => false,
            'markup_percent' => null,
            'is_active' => true,
            'created_by_user_id' => $ctx['ownerUser']->id,
        ]);
        foreach ([$ctx['cpHead'], $ctx['cpPartner']] as $cp) {
            ProjectExpenseItemProfitShare::query()->create([
                'expense_item_id' => $ei2->id,
                'counterparty_id' => $cp->id,
                'percent' => '50.00',
            ]);
        }

        $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $p2->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ppPartnerP2->id,
            customerPpId: (int) $ppCustomerP2->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ei2->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: Carbon::parse('2026-05-06 08:00:00', 'UTC'),
            deltaCents: 20_000,
        );
        $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppPartner']->id,
            amount: '50.00',
            appliedAt: Carbon::parse('2026-05-07 08:00:00', 'UTC'),
        );

        Sanctum::actingAs($ctx['partnerUser']);
        $res = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics");
        $res->assertOk();
        self::assertSame('200.00', $res->json('data.debt_total'));
        self::assertSame('50.00', $res->json('data.overpayment_total'));
    }

    public function test_overpayment_operations_returns_aggregate_payload(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppPartner']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: Carbon::parse('2026-05-03 08:00:00', 'UTC'),
            deltaCents: 5_000,
        );
        $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppPartner']->id,
            amount: '80.00',
            appliedAt: Carbon::parse('2026-05-04 08:00:00', 'UTC'),
        );

        Sanctum::actingAs($ctx['partnerUser']);
        $ops = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics/operations?metric=overpayment");
        $ops->assertOk();
        $items = $ops->json('data.items');
        self::assertNotEmpty($items);
        $row = $items[0];
        self::assertSame('overpayment', $row['metric']);
        self::assertSame('aggregate', $row['operation_kind']);
        self::assertNull($row['operation_id']);
        self::assertSame('P-analytics', $row['project_name']);
        self::assertSame('50.00', $row['earned_amount']);
        self::assertSame('80.00', $row['received_amount']);
        self::assertSame('30.00', $row['overpayment_amount']);
        self::assertSame('30.00', $row['metric_amount']);
    }

    public function test_overpayment_project_detail_returns_transfers_and_reports(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppPartner']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: Carbon::parse('2026-05-03 08:00:00', 'UTC'),
            deltaCents: 5_000,
        );
        $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppPartner']->id,
            amount: '80.00',
            appliedAt: Carbon::parse('2026-05-04 08:00:00', 'UTC'),
        );

        Sanctum::actingAs($ctx['partnerUser']);
        $res = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics/overpayment-detail?project_id={$ctx['project']->id}");
        $res->assertOk();
        self::assertSame('P-analytics', $res->json('data.project_name'));
        self::assertSame('50.00', $res->json('data.earned_amount'));
        self::assertSame('80.00', $res->json('data.received_amount'));
        self::assertSame('30.00', $res->json('data.overpayment_amount'));
        $transfers = $res->json('data.transfers');
        self::assertIsArray($transfers);
        self::assertCount(1, $transfers);
        self::assertSame('transfer', $transfers[0]['operation_kind']);
        self::assertSame('80.00', $transfers[0]['metric_amount']);
        $reports = $res->json('data.reports');
        self::assertIsArray($reports);
        self::assertNotEmpty($reports);
        self::assertSame('report', $reports[0]['operation_kind']);
        self::assertSame('50.00', $reports[0]['earned_amount']);
    }

    public function test_debt_operations_returns_earned_received_debt_amounts(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppPartner']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: Carbon::parse('2026-05-10 08:00:00', 'UTC'),
            deltaCents: 50_000,
        );
        $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppPartner']->id,
            amount: '225.50',
            appliedAt: Carbon::parse('2026-05-11 08:00:00', 'UTC'),
        );
        $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppPartner']->id,
            amount: '200.00',
            appliedAt: Carbon::parse('2026-05-12 08:00:00', 'UTC'),
        );

        Sanctum::actingAs($ctx['partnerUser']);
        $debt = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics/operations?metric=debt");
        $debt->assertOk();
        $ditems = $debt->json('data.items');
        self::assertNotEmpty($ditems);
        $dr = $ditems[0];
        self::assertSame('debt', $dr['metric']);
        self::assertSame('500.00', $dr['earned_amount']);
        self::assertSame('425.50', $dr['received_amount']);
        self::assertSame('74.50', $dr['debt_amount']);
        self::assertSame('74.50', $dr['metric_amount']);
    }

    public function test_reverted_report_delta_excluded(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        $applied = Carbon::parse('2026-05-05 08:00:00', 'UTC');
        $rid = $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppPartner']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: $applied,
            deltaCents: 9_999,
        );
        ReportWalletDelta::query()
            ->where('report_operation_id', $rid)
            ->update(['reverted_at' => Carbon::parse('2026-05-06 08:00:00', 'UTC')]);

        Sanctum::actingAs($ctx['partnerUser']);
        $res = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics");
        $res->assertOk();
        self::assertSame('0.00', $res->json('data.debt_total'));
    }

    public function test_reverted_transfer_excluded_from_income(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        $tid = $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppPartner']->id,
            amount: '15.00',
            appliedAt: Carbon::parse('2026-05-07 08:00:00', 'UTC'),
        );
        TransferOperation::query()->whereKey($tid)->update([
            'wallets_reverted_at' => Carbon::parse('2026-05-08 08:00:00', 'UTC'),
        ]);

        Sanctum::actingAs($ctx['partnerUser']);
        $res = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics");
        $res->assertOk();
        self::assertSame('0.00', $res->json('data.income_total'));
    }

    public function test_month_query_limits_income_and_sets_as_of_end_of_month(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppPartner']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: Carbon::parse('2026-04-20 08:00:00', 'UTC'),
            deltaCents: 40_000,
        );
        $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppPartner']->id,
            amount: '10.00',
            appliedAt: Carbon::parse('2026-05-10 08:00:00', 'UTC'),
        );

        Sanctum::actingAs($ctx['partnerUser']);
        $may = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics?month=2026-05");
        $may->assertOk();
        self::assertSame('10.00', $may->json('data.income_total'));
        self::assertSame('390.00', $may->json('data.debt_total'));

        $apr = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics?month=2026-04");
        $apr->assertOk();
        self::assertSame('0.00', $apr->json('data.income_total'));
        self::assertSame('400.00', $apr->json('data.debt_total'));
    }

    public function test_partner_active_projects_only_as_project_head_first(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();

        $p2 = Project::query()->create([
            'company_id' => $ctx['company']->id,
            'name' => 'P-partner-head',
            'progress_percent' => 0,
            'is_active' => true,
        ]);
        $cpCustomer2 = Counterparty::query()->create([
            'company_id' => $ctx['company']->id,
            'user_id' => User::factory()->create()->id,
            'company_role_code' => CompanyRoleCode::CUSTOMER->value,
            'is_active' => true,
        ]);
        $ppPartnerHead = ProjectParticipant::query()->create([
            'project_id' => $p2->id,
            'counterparty_id' => $ctx['cpPartner']->id,
            'project_role_code' => ProjectRoleCode::PROJECT_HEAD->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $ppCustomer2 = ProjectParticipant::query()->create([
            'project_id' => $p2->id,
            'counterparty_id' => $cpCustomer2->id,
            'project_role_code' => ProjectRoleCode::CUSTOMER->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $w = app(WalletFactoryService::class);
        $w->createForParticipant($ppPartnerHead);
        $w->createForParticipant($ppCustomer2);

        Sanctum::actingAs($ctx['partnerUser']);
        $res = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics");
        $res->assertOk();
        self::assertSame(1, (int) $res->json('data.active_projects_total'));
    }

    public function test_operations_endpoint_requires_valid_metric(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        Sanctum::actingAs($ctx['ownerUser']);
        $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics/operations?metric=bad")
            ->assertStatus(422);
    }

    public function test_dashboard_analytics_operations_payload_has_project_name_and_metric_amounts(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-05-15 12:00:00', 'UTC'));
        $ctx = $this->seedOwnerPartnerProjectFixture();
        Project::query()->whereKey($ctx['project']->id)->update(['name' => 'ЖК Проверка']);

        $rid = $this->createAppliedReportWithPersonalEarned(
            companyId: $ctx['company']->id,
            projectId: $ctx['project']->id,
            initiatorPpId: (int) $ctx['ppHead']->id,
            recipientPpId: (int) $ctx['ppPartner']->id,
            customerPpId: (int) $ctx['ppCustomer']->id,
            recipientCpId: (int) $ctx['cpPartner']->id,
            expenseItemId: (int) $ctx['expenseItem']->id,
            createdByUserId: (int) $ctx['ownerUser']->id,
            appliedAt: Carbon::parse('2026-05-10 08:00:00', 'UTC'),
            deltaCents: 50_000,
        );
        ReportOperation::query()->whereKey($rid)->update(['operation_number' => null]);

        Sanctum::actingAs($ctx['ownerUser']);
        $inc = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics/operations?metric=income");
        $inc->assertOk();
        $items = $inc->json('data.items');
        self::assertIsArray($items);
        self::assertNotEmpty($items);
        $row = $items[0];
        self::assertSame('report', $row['operation_kind']);
        self::assertSame('ЖК Проверка', $row['project_name']);
        self::assertSame('500.00', $row['metric_amount']);
        self::assertNull($row['operation_number']);
        self::assertSame('REP-'.$rid, $row['subtitle']);

        $tid = $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppPartner']->id,
            amount: '25.50',
            appliedAt: Carbon::parse('2026-05-11 08:00:00', 'UTC'),
        );
        TransferOperation::query()->whereKey($tid)->update(['operation_number' => 'TRF-UNIT']);

        $this->createPersonalBalanceTransfer(
            projectId: (int) $ctx['project']->id,
            senderPpId: (int) $ctx['ppHead']->id,
            receiverPpId: (int) $ctx['ppPartner']->id,
            amount: '200.00',
            appliedAt: Carbon::parse('2026-05-12 08:00:00', 'UTC'),
        );

        Sanctum::actingAs($ctx['partnerUser']);
        $pt = $this->getJson("/api/company-workspace/{$ctx['company']->id}/dashboard/analytics/operations?metric=income");
        $pt->assertOk();
        $titems = $pt->json('data.items');
        self::assertNotEmpty($titems);
        $amounts = array_map(static fn ($r) => (string) ($r['metric_amount'] ?? ''), $titems);
        self::assertContains('25.50', $amounts);
        self::assertContains('200.00', $amounts);
        $tr = $titems[array_search('25.50', $amounts, true)];
        self::assertSame('transfer', $tr['operation_kind']);
        self::assertSame('ЖК Проверка', $tr['project_name']);
        self::assertSame('TRF-UNIT', $tr['operation_number']);
    }

    /**
     * @return array{
     *   company: Company,
     *   project: Project,
     *   ownerUser: User,
     *   partnerUser: User,
     *   customerUser: User,
     *   cpHead: Counterparty,
     *   cpPartner: Counterparty,
     *   cpCustomer: Counterparty,
     *   ppHead: ProjectParticipant,
     *   ppPartner: ProjectParticipant,
     *   ppCustomer: ProjectParticipant,
     *   expenseItem: ProjectExpenseItem,
     * }
     */
    private function seedOwnerPartnerProjectFixture(): array
    {
        $ownerUser = User::factory()->create();
        $partnerUser = User::factory()->create();
        $customerUser = User::factory()->create();

        $company = Company::query()->create([
            'name' => 'Co Analytics',
            'created_by_user_id' => $ownerUser->id,
            'is_active' => true,
        ]);

        $cpHead = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $ownerUser->id,
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
            'name' => 'P-analytics',
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
            'name' => 'EI-analytics',
            'markup_enabled' => false,
            'markup_percent' => null,
            'is_active' => true,
            'created_by_user_id' => $ownerUser->id,
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
            'ownerUser' => $ownerUser,
            'partnerUser' => $partnerUser,
            'customerUser' => $customerUser,
            'cpHead' => $cpHead,
            'cpPartner' => $cpPartner,
            'cpCustomer' => $cpCustomer,
            'ppHead' => $ppHead,
            'ppPartner' => $ppPartner,
            'ppCustomer' => $ppCustomer,
            'expenseItem' => $expenseItem,
        ];
    }

    private function createAppliedReportWithPersonalEarned(
        int $companyId,
        int $projectId,
        int $initiatorPpId,
        int $recipientPpId,
        int $customerPpId,
        int $recipientCpId,
        int $expenseItemId,
        int $createdByUserId,
        Carbon $appliedAt,
        int $deltaCents,
    ): int {
        $report = ReportOperation::query()->create([
            'operation_number' => null,
            'company_id' => $companyId,
            'project_id' => $projectId,
            'initiator_project_participant_id' => $initiatorPpId,
            'recipient_counterparty_id' => $recipientCpId,
            'recipient_project_participant_id' => $recipientPpId,
            'customer_project_participant_id' => $customerPpId,
            'expense_item_id' => $expenseItemId,
            'operation_date' => $appliedAt->format('Y-m-d'),
            'operation_status' => OperationStatus::COMPLETED,
            'recipient_amount' => '0.00',
            'customer_base_amount' => '0.00',
            'markup_amount' => '0.00',
            'customer_total_amount' => '0.00',
            'profit_amount' => '0.00',
            'comment' => null,
            'wallets_applied_at' => $appliedAt,
            'wallets_reverted_at' => null,
            'waiting_period_started_at' => null,
            'completed_at' => $appliedAt,
            'created_by_user_id' => $createdByUserId,
            'updated_by_user_id' => null,
        ]);
        $report->update(['operation_number' => 'REP-'.$report->id]);

        ReportWalletDelta::query()->create([
            'report_operation_id' => $report->id,
            'project_participant_id' => $recipientPpId,
            'wallet_id' => null,
            'field_name' => 'personal_earned',
            'delta_cents' => $deltaCents,
            'applied_at' => $appliedAt,
            'reverted_at' => null,
        ]);

        return (int) $report->id;
    }

    private function createPersonalBalanceTransfer(
        int $projectId,
        int $senderPpId,
        int $receiverPpId,
        string $amount,
        Carbon $appliedAt,
    ): int {
        $op = Operation::query()->create([
            'project_id' => $projectId,
            'initiator_project_participant_id' => $senderPpId,
            'operation_type' => OperationType::TRANSFER,
            'operation_status' => OperationStatus::COMPLETED,
        ]);
        $transfer = TransferOperation::query()->create([
            'operation_id' => $op->id,
            'project_id' => $projectId,
            'initiator_project_participant_id' => $senderPpId,
            'sender_project_participant_id' => $senderPpId,
            'receiver_project_participant_id' => $receiverPpId,
            'transfer_target_type' => TransferTargetType::PERSONAL_BALANCE,
            'amount' => $amount,
            'comment' => null,
            'operation_status' => OperationStatus::COMPLETED,
            'wallets_applied_at' => $appliedAt,
            'wallets_reverted_at' => null,
        ]);
        $transfer->update(['operation_number' => 'TRF-'.$transfer->id]);

        return (int) $transfer->id;
    }
}
