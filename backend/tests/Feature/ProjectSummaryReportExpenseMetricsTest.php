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
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Models\Operation;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectExpenseItem;
use App\Modules\Projects\Models\ProjectExpenseItemProfitShare;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\ProjectSummaryMetricsService;
use App\Modules\Projects\Services\WalletFactoryService;
use Carbon\Carbon;
use Database\Seeders\CompanyRoleSeeder;
use Database\Seeders\ProjectRoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Карточка «Показатели проекта» (GET …/summary): расход по REPORT с применёнными дельтами.
 */
final class ProjectSummaryReportExpenseMetricsTest extends TestCase
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

    public function test_report_expense_and_balance_via_metrics_service(): void
    {
        $ctx = $this->seedProjectWithReportPrerequisites();
        $project = $ctx['project'];
        $metrics = app(ProjectSummaryMetricsService::class);

        $this->insertIncomeApplied($ctx, '500000.00');

        $this->insertReport($ctx, [
            'customer_total_amount' => '120000.00',
            'wallets_applied_at'    => Carbon::now('UTC'),
            'wallets_reverted_at'   => null,
        ]);

        self::assertSame('120000.00', $metrics->reportExpenseTotalApplied($project));
        self::assertSame('500000.00', $metrics->incomeTotalApplied($project));
        self::assertSame('380000.00', $metrics->summaryProjectBalanceIncomeMinusExpense($project));
    }

    public function test_report_without_wallets_applied_not_in_expense(): void
    {
        $ctx = $this->seedProjectWithReportPrerequisites();
        $project = $ctx['project'];
        $metrics = app(ProjectSummaryMetricsService::class);

        $this->insertReport($ctx, [
            'customer_total_amount' => '999.00',
            'wallets_applied_at'    => null,
            'wallets_reverted_at'   => null,
        ]);

        self::assertSame('0.00', $metrics->reportExpenseTotalApplied($project));
    }

    public function test_report_with_wallets_reverted_at_not_in_expense(): void
    {
        $ctx = $this->seedProjectWithReportPrerequisites();
        $project = $ctx['project'];
        $metrics = app(ProjectSummaryMetricsService::class);

        $this->insertReport($ctx, [
            'customer_total_amount' => '50000.00',
            'wallets_applied_at'    => Carbon::now('UTC'),
            'wallets_reverted_at'   => Carbon::now('UTC'),
        ]);

        self::assertSame('0.00', $metrics->reportExpenseTotalApplied($project));
    }

    public function test_company_project_summary_json_matches_expense(): void
    {
        $ctx = $this->seedProjectWithReportPrerequisites();
        $project = $ctx['project'];
        $company = $ctx['company'];
        $headUser = $ctx['headUser'];

        $this->insertReport($ctx, [
            'customer_total_amount' => '120000.00',
            'wallets_applied_at'    => Carbon::now('UTC'),
            'wallets_reverted_at'   => null,
        ]);

        Sanctum::actingAs($headUser);
        $res = $this->getJson("/api/company-workspace/{$company->id}/projects/{$project->id}/summary");
        $res->assertOk();
        $res->assertJsonPath('data.metrics.expense_total', '120000.00');
    }

    /**
     * @return array{
     *   company: Company,
     *   project: Project,
     *   headUser: User,
     *   cpPartner: Counterparty,
     *   cpCustomer: Counterparty,
     *   ppHead: ProjectParticipant,
     *   ppPartner: ProjectParticipant,
     *   ppCustomer: ProjectParticipant,
     *   expenseItem: ProjectExpenseItem,
     * }
     */
    private function seedProjectWithReportPrerequisites(): array
    {
        $headUser = User::factory()->create();
        $partnerUser = User::factory()->create();
        $customerUser = User::factory()->create();

        $company = Company::query()->create([
            'name'               => 'Co Summary Metrics',
            'created_by_user_id' => $headUser->id,
            'is_active'          => true,
        ]);

        $cpHead = Counterparty::query()->create([
            'company_id'        => $company->id,
            'user_id'           => $headUser->id,
            'company_role_code' => CompanyRoleCode::OWNER->value,
            'is_active'         => true,
        ]);
        $cpPartner = Counterparty::query()->create([
            'company_id'        => $company->id,
            'user_id'           => $partnerUser->id,
            'company_role_code' => CompanyRoleCode::PARTNER->value,
            'is_active'         => true,
        ]);
        $cpCustomer = Counterparty::query()->create([
            'company_id'        => $company->id,
            'user_id'           => $customerUser->id,
            'company_role_code' => CompanyRoleCode::CUSTOMER->value,
            'is_active'         => true,
        ]);

        $project = Project::query()->create([
            'company_id'       => $company->id,
            'name'             => 'P-Summary',
            'progress_percent' => 0,
            'is_active'        => true,
        ]);

        $ppHead = ProjectParticipant::query()->create([
            'project_id'          => $project->id,
            'counterparty_id'     => $cpHead->id,
            'project_role_code'   => ProjectRoleCode::PROJECT_HEAD->value,
            'level'               => 'first',
            'is_active'           => true,
        ]);
        $ppPartner = ProjectParticipant::query()->create([
            'project_id'          => $project->id,
            'counterparty_id'     => $cpPartner->id,
            'project_role_code'   => ProjectRoleCode::PARTNER->value,
            'level'               => 'first',
            'is_active'           => true,
        ]);
        $ppCustomer = ProjectParticipant::query()->create([
            'project_id'          => $project->id,
            'counterparty_id'     => $cpCustomer->id,
            'project_role_code'   => ProjectRoleCode::CUSTOMER->value,
            'level'               => 'first',
            'is_active'           => true,
        ]);

        $wallets = app(WalletFactoryService::class);
        $wallets->createForParticipant($ppHead);
        $wallets->createForParticipant($ppPartner);
        $wallets->createForParticipant($ppCustomer);

        $expenseItem = ProjectExpenseItem::query()->create([
            'project_id'         => $project->id,
            'name'               => 'EI-Summary',
            'markup_enabled'     => false,
            'markup_percent'     => null,
            'is_active'          => true,
            'created_by_user_id' => $headUser->id,
        ]);
        foreach ([$cpHead, $cpPartner] as $cp) {
            ProjectExpenseItemProfitShare::query()->create([
                'expense_item_id' => $expenseItem->id,
                'counterparty_id' => $cp->id,
                'percent'         => '50.00',
            ]);
        }

        return [
            'company'     => $company,
            'project'     => $project,
            'headUser'    => $headUser,
            'cpPartner'   => $cpPartner,
            'cpCustomer'  => $cpCustomer,
            'ppHead'      => $ppHead,
            'ppPartner'   => $ppPartner,
            'ppCustomer'  => $ppCustomer,
            'expenseItem' => $expenseItem,
        ];
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    private function insertReport(array $ctx, array $overrides): ReportOperation
    {
        $defaults = [
            'operation_number'                   => null,
            'company_id'                         => $ctx['company']->id,
            'project_id'                         => $ctx['project']->id,
            'initiator_project_participant_id'   => $ctx['ppHead']->id,
            'recipient_counterparty_id'          => $ctx['cpPartner']->id,
            'recipient_project_participant_id'   => $ctx['ppPartner']->id,
            'customer_project_participant_id'    => $ctx['ppCustomer']->id,
            'expense_item_id'                    => $ctx['expenseItem']->id,
            'operation_date'                     => Carbon::now()->format('Y-m-d'),
            'operation_status'                   => OperationStatus::COMPLETED,
            'recipient_amount'                   => '0.00',
            'customer_base_amount'               => '0.00',
            'markup_amount'                      => '0.00',
            'customer_total_amount'              => '0.00',
            'profit_amount'                      => '0.00',
            'comment'                            => null,
            'wallets_applied_at'                 => null,
            'wallets_reverted_at'                => null,
            'waiting_period_started_at'        => null,
            'completed_at'                       => null,
            'created_by_user_id'                 => $ctx['headUser']->id,
            'updated_by_user_id'               => null,
        ];

        return ReportOperation::query()->create(array_merge($defaults, $overrides));
    }

    private function insertIncomeApplied(array $ctx, string $amount): IncomeOperation
    {
        $op = Operation::query()->create([
            'project_id'                      => $ctx['project']->id,
            'initiator_project_participant_id' => $ctx['ppHead']->id,
            'operation_type'                  => OperationType::INCOME,
            'operation_status'                => OperationStatus::COMPLETED,
        ]);

        return IncomeOperation::query()->create([
            'operation_id'                      => $op->id,
            'project_id'                        => $ctx['project']->id,
            'initiator_project_participant_id'  => $ctx['ppHead']->id,
            'project_head_project_participant_id' => $ctx['ppHead']->id,
            'customer_project_participant_id'   => $ctx['ppCustomer']->id,
            'amount'                            => $amount,
            'operation_status'                  => OperationStatus::COMPLETED,
            'wallets_applied_at'                => Carbon::now('UTC'),
            'wallets_reverted_at'             => null,
        ]);
    }
}
