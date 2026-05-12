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
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Models\Operation;
use App\Modules\Operations\Models\TransferOperation;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Carbon\Carbon;
use Database\Seeders\CompanyRoleSeeder;
use Database\Seeders\ProjectRoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Агрегированная история: вкладки tab=all|tab=pending и счётчики pending (см. AggregatedOperationsHistoryService).
 */
final class AggregatedOperationsHistoryTabsTest extends TestCase
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

    public function test_company_owner_tab_all_sees_transfer_without_project_participation(): void
    {
        $fixture = $this->createCompanyWithEmployeeTransferAwaitingHead();

        Sanctum::actingAs($fixture->ownerUser);
        $res = $this->getJson("/api/company-workspace/{$fixture->companyId}/operations/history?tab=all&per_page=50");

        $res->assertOk()->assertJsonPath('ok', true);
        $ids = $this->transferIdsFromItems($res->json('data.items'));
        self::assertContains($fixture->transferId, $ids, 'OWNER должен видеть перевод компании во вкладке all без участия в проекте');
    }

    public function test_company_owner_tab_pending_skips_head_queue_when_owner_not_in_project(): void
    {
        $fixture = $this->createCompanyWithEmployeeTransferAwaitingHead();

        Sanctum::actingAs($fixture->ownerUser);
        $res = $this->getJson("/api/company-workspace/{$fixture->companyId}/operations/history?tab=pending&per_page=50");

        $res->assertOk();
        $ids = $this->transferIdsFromItems($res->json('data.items'));
        self::assertNotContains(
            $fixture->transferId,
            $ids,
            'OWNER без участия в проекте не должен видеть чужой PROJECT_HEAD_APPROVAL в pending',
        );
    }

    public function test_company_partner_tab_all_hides_employee_only_transfer_when_partner_not_in_operation(): void
    {
        $fixture = $this->createCompanyWithEmployeeTransferAwaitingHead();
        $this->addSidePartnerParticipant($fixture);

        Sanctum::actingAs($fixture->sidePartnerUser);
        $res = $this->getJson("/api/company-workspace/{$fixture->companyId}/operations/history?tab=all&per_page=50");

        $res->assertOk();
        $ids = $this->transferIdsFromItems($res->json('data.items'));
        self::assertNotContains(
            $fixture->transferId,
            $ids,
            'PARTNER без ролей initiator/sender/receiver в переводе не видит его во вкладке all',
        );
    }

    public function test_customer_personal_pending_includes_customer_approval_excludes_waiting_24(): void
    {
        $fixture = $this->createProjectWithCustomerIncomes();

        Sanctum::actingAs($fixture->customerUser);
        $res = $this->getJson('/api/personal-workspace/operations/history?tab=pending&per_page=50');

        $res->assertOk();
        $incomeIds = $this->incomeIdsFromItems($res->json('data.items'));
        self::assertContains($fixture->incomeCustomerApprovalId, $incomeIds);
        self::assertNotContains($fixture->incomeWaiting24Id, $incomeIds);
    }

    public function test_customer_personal_pending_count_excludes_waiting_24_income(): void
    {
        $fixture = $this->createProjectWithCustomerIncomes();

        Sanctum::actingAs($fixture->customerUser);
        $res = $this->getJson('/api/personal-workspace/operations/incomes/pending-count');

        $res->assertOk()->assertJsonPath('data.pending_action_count', 1);
    }

    public function test_customer_personal_tab_all_lists_both_incomes_when_customer_participates(): void
    {
        $fixture = $this->createProjectWithCustomerIncomes();

        Sanctum::actingAs($fixture->customerUser);
        $res = $this->getJson('/api/personal-workspace/operations/history?tab=all&per_page=50');

        $res->assertOk();
        $ids = $this->incomeIdsFromItems($res->json('data.items'));
        self::assertContains($fixture->incomeCustomerApprovalId, $ids);
        self::assertContains($fixture->incomeWaiting24Id, $ids);
    }

    public function test_initiator_personal_transfer_pending_count_excludes_waiting_24_hours(): void
    {
        $fixture = $this->createCompanyWithEmployeeTransferInWaiting24();

        Sanctum::actingAs($fixture->employeeInitiatorUser);
        $res = $this->getJson('/api/personal-workspace/operations/transfers/pending-count');

        $res->assertOk()->assertJsonPath('data.pending_action_count', 0);
    }

    public function test_created_transfer_pending_visible_only_to_employee_initiator(): void
    {
        $fixture = $this->createCompanyWithEmployeeTransferCreated();

        Sanctum::actingAs($fixture->employeeInitiatorUser);
        $rInit = $this->getJson('/api/personal-workspace/operations/history?tab=pending&per_page=50');
        $rInit->assertOk();
        self::assertContains($fixture->transferId, $this->transferIdsFromItems($rInit->json('data.items')));

        Sanctum::actingAs($fixture->employeeReceiverUser);
        $rRecv = $this->getJson('/api/personal-workspace/operations/history?tab=pending&per_page=50');
        $rRecv->assertOk();
        self::assertNotContains($fixture->transferId, $this->transferIdsFromItems($rRecv->json('data.items')));
    }

    public function test_company_partner_tab_pending_includes_head_approval_for_project_head(): void
    {
        $fixture = $this->createCompanyWithEmployeeTransferAwaitingHead();

        Sanctum::actingAs($fixture->headPartnerUser);
        $res = $this->getJson("/api/company-workspace/{$fixture->companyId}/operations/history?tab=pending&per_page=50");

        $res->assertOk();
        self::assertContains($fixture->transferId, $this->transferIdsFromItems($res->json('data.items')));
    }

    /**
     * @param list<array<string, mixed>>|null $items
     *
     * @return list<int>
     */
    private function transferIdsFromItems(?array $items): array
    {
        $items ??= [];
        $ids = [];
        foreach ($items as $item) {
            if (($item['operation_kind'] ?? '') === 'transfer' && isset($item['transfer']['id'])) {
                $ids[] = (int) $item['transfer']['id'];
            }
        }

        return $ids;
    }

    /**
     * @param list<array<string, mixed>>|null $items
     *
     * @return list<int>
     */
    private function incomeIdsFromItems(?array $items): array
    {
        $items ??= [];
        $ids = [];
        foreach ($items as $item) {
            if (($item['operation_kind'] ?? '') === 'income' && isset($item['income']['id'])) {
                $ids[] = (int) $item['income']['id'];
            }
        }

        return $ids;
    }

    private function createCompanyWithEmployeeTransferAwaitingHead(): EmployeeTransferFixture
    {
        $owner = User::factory()->create();
        $headPartner = User::factory()->create();
        $empInit = User::factory()->create();
        $empRecv = User::factory()->create();

        $company = Company::query()->create([
            'name' => 'Test Co',
            'created_by_user_id' => $owner->id,
            'is_active' => true,
        ]);

        $cpOwner = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $owner->id,
            'company_role_code' => CompanyRoleCode::OWNER->value,
            'is_active' => true,
        ]);
        $cpHead = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $headPartner->id,
            'company_role_code' => CompanyRoleCode::PARTNER->value,
            'is_active' => true,
        ]);
        $cpEmpInit = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $empInit->id,
            'company_role_code' => CompanyRoleCode::EMPLOYEE->value,
            'is_active' => true,
        ]);
        $cpEmpRecv = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $empRecv->id,
            'company_role_code' => CompanyRoleCode::EMPLOYEE->value,
            'is_active' => true,
        ]);

        $project = Project::query()->create([
            'company_id' => $company->id,
            'name' => 'Proj',
            'is_active' => true,
        ]);

        $ppHead = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpHead->id,
            'project_role_code' => ProjectRoleCode::PROJECT_HEAD->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $ppInit = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpEmpInit->id,
            'project_role_code' => ProjectRoleCode::EMPLOYEE->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $ppRecv = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpEmpRecv->id,
            'project_role_code' => ProjectRoleCode::EMPLOYEE->value,
            'level' => 'first',
            'is_active' => true,
        ]);

        $operation = Operation::query()->create([
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppInit->id,
            'operation_type' => OperationType::TRANSFER,
            'operation_status' => OperationStatus::PROJECT_HEAD_APPROVAL,
        ]);

        $transfer = TransferOperation::query()->create([
            'operation_id' => $operation->id,
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppInit->id,
            'sender_project_participant_id' => $ppInit->id,
            'receiver_project_participant_id' => $ppRecv->id,
            'transfer_target_type' => TransferTargetType::PERSONAL_BALANCE,
            'amount' => '10.00',
            'comment' => null,
            'operation_status' => OperationStatus::PROJECT_HEAD_APPROVAL,
            'wallets_applied_at' => null,
        ]);

        $f = new EmployeeTransferFixture;
        $f->companyId = (int) $company->id;
        $f->ownerUser = $owner;
        $f->headPartnerUser = $headPartner;
        $f->employeeInitiatorUser = $empInit;
        $f->employeeReceiverUser = $empRecv;
        $f->transferId = (int) $transfer->id;
        $f->projectId = (int) $project->id;
        $f->cpOwnerId = (int) $cpOwner->id;
        $f->cpHeadId = (int) $cpHead->id;

        return $f;
    }

    private function addSidePartnerParticipant(EmployeeTransferFixture $fixture): void
    {
        $sideUser = User::factory()->create();
        $cpSide = Counterparty::query()->create([
            'company_id' => $fixture->companyId,
            'user_id' => $sideUser->id,
            'company_role_code' => CompanyRoleCode::PARTNER->value,
            'is_active' => true,
        ]);
        ProjectParticipant::query()->create([
            'project_id' => $fixture->projectId,
            'counterparty_id' => $cpSide->id,
            'project_role_code' => ProjectRoleCode::PARTNER->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $fixture->sidePartnerUser = $sideUser;
    }

    private function createProjectWithCustomerIncomes(): CustomerIncomesFixture
    {
        $owner = User::factory()->create();
        $headPartner = User::factory()->create();
        $customer = User::factory()->create();

        $company = Company::query()->create([
            'name' => 'Co Customer',
            'created_by_user_id' => $owner->id,
            'is_active' => true,
        ]);

        Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $owner->id,
            'company_role_code' => CompanyRoleCode::OWNER->value,
            'is_active' => true,
        ]);
        $cpHead = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $headPartner->id,
            'company_role_code' => CompanyRoleCode::PARTNER->value,
            'is_active' => true,
        ]);
        $cpCustomer = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $customer->id,
            'company_role_code' => CompanyRoleCode::CUSTOMER->value,
            'is_active' => true,
        ]);

        $project = Project::query()->create([
            'company_id' => $company->id,
            'name' => 'P',
            'is_active' => true,
        ]);

        $ppHead = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpHead->id,
            'project_role_code' => ProjectRoleCode::PROJECT_HEAD->value,
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

        $opA = Operation::query()->create([
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppHead->id,
            'operation_type' => OperationType::INCOME,
            'operation_status' => OperationStatus::CUSTOMER_APPROVAL,
        ]);
        $incA = IncomeOperation::query()->create([
            'operation_id' => $opA->id,
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppHead->id,
            'project_head_project_participant_id' => $ppHead->id,
            'customer_project_participant_id' => $ppCustomer->id,
            'amount' => '100.00',
            'comment' => null,
            'operation_status' => OperationStatus::CUSTOMER_APPROVAL,
            'wallets_applied_at' => Carbon::now(),
        ]);

        $opB = Operation::query()->create([
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppHead->id,
            'operation_type' => OperationType::INCOME,
            'operation_status' => OperationStatus::WAITING_24_HOURS,
        ]);
        $incB = IncomeOperation::query()->create([
            'operation_id' => $opB->id,
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppHead->id,
            'project_head_project_participant_id' => $ppHead->id,
            'customer_project_participant_id' => $ppCustomer->id,
            'amount' => '200.00',
            'comment' => null,
            'operation_status' => OperationStatus::WAITING_24_HOURS,
            'wallets_applied_at' => Carbon::now(),
            'waiting_period_started_at' => Carbon::now(),
        ]);

        $f = new CustomerIncomesFixture;
        $f->customerUser = $customer;
        $f->incomeCustomerApprovalId = (int) $incA->id;
        $f->incomeWaiting24Id = (int) $incB->id;

        return $f;
    }

    private function createCompanyWithEmployeeTransferInWaiting24(): EmployeeTransferFixture
    {
        $owner = User::factory()->create();
        $headPartner = User::factory()->create();
        $empInit = User::factory()->create();
        $empRecv = User::factory()->create();

        $company = Company::query()->create([
            'name' => 'Co W24',
            'created_by_user_id' => $owner->id,
            'is_active' => true,
        ]);

        Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $owner->id,
            'company_role_code' => CompanyRoleCode::OWNER->value,
            'is_active' => true,
        ]);
        $cpHead = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $headPartner->id,
            'company_role_code' => CompanyRoleCode::PARTNER->value,
            'is_active' => true,
        ]);
        $cpEmpInit = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $empInit->id,
            'company_role_code' => CompanyRoleCode::EMPLOYEE->value,
            'is_active' => true,
        ]);
        $cpEmpRecv = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $empRecv->id,
            'company_role_code' => CompanyRoleCode::EMPLOYEE->value,
            'is_active' => true,
        ]);

        $project = Project::query()->create([
            'company_id' => $company->id,
            'name' => 'P',
            'is_active' => true,
        ]);

        $ppHead = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpHead->id,
            'project_role_code' => ProjectRoleCode::PROJECT_HEAD->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $ppInit = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpEmpInit->id,
            'project_role_code' => ProjectRoleCode::EMPLOYEE->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $ppRecv = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpEmpRecv->id,
            'project_role_code' => ProjectRoleCode::EMPLOYEE->value,
            'level' => 'first',
            'is_active' => true,
        ]);

        $operation = Operation::query()->create([
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppInit->id,
            'operation_type' => OperationType::TRANSFER,
            'operation_status' => OperationStatus::WAITING_24_HOURS,
        ]);

        $transfer = TransferOperation::query()->create([
            'operation_id' => $operation->id,
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppInit->id,
            'sender_project_participant_id' => $ppInit->id,
            'receiver_project_participant_id' => $ppRecv->id,
            'transfer_target_type' => TransferTargetType::PERSONAL_BALANCE,
            'amount' => '5.00',
            'comment' => null,
            'operation_status' => OperationStatus::WAITING_24_HOURS,
            'wallets_applied_at' => Carbon::now(),
        ]);

        $f = new EmployeeTransferFixture;
        $f->companyId = (int) $company->id;
        $f->employeeInitiatorUser = $empInit;
        $f->transferId = (int) $transfer->id;
        $f->ppHeadId = (int) $ppHead->id;

        return $f;
    }

    private function createCompanyWithEmployeeTransferCreated(): EmployeeTransferFixture
    {
        $owner = User::factory()->create();
        $headPartner = User::factory()->create();
        $empInit = User::factory()->create();
        $empRecv = User::factory()->create();

        $company = Company::query()->create([
            'name' => 'Co Created',
            'created_by_user_id' => $owner->id,
            'is_active' => true,
        ]);

        Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $owner->id,
            'company_role_code' => CompanyRoleCode::OWNER->value,
            'is_active' => true,
        ]);
        $cpHead = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $headPartner->id,
            'company_role_code' => CompanyRoleCode::PARTNER->value,
            'is_active' => true,
        ]);
        $cpEmpInit = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $empInit->id,
            'company_role_code' => CompanyRoleCode::EMPLOYEE->value,
            'is_active' => true,
        ]);
        $cpEmpRecv = Counterparty::query()->create([
            'company_id' => $company->id,
            'user_id' => $empRecv->id,
            'company_role_code' => CompanyRoleCode::EMPLOYEE->value,
            'is_active' => true,
        ]);

        $project = Project::query()->create([
            'company_id' => $company->id,
            'name' => 'P',
            'is_active' => true,
        ]);

        $ppHead = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpHead->id,
            'project_role_code' => ProjectRoleCode::PROJECT_HEAD->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $ppInit = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpEmpInit->id,
            'project_role_code' => ProjectRoleCode::EMPLOYEE->value,
            'level' => 'first',
            'is_active' => true,
        ]);
        $ppRecv = ProjectParticipant::query()->create([
            'project_id' => $project->id,
            'counterparty_id' => $cpEmpRecv->id,
            'project_role_code' => ProjectRoleCode::EMPLOYEE->value,
            'level' => 'first',
            'is_active' => true,
        ]);

        $operation = Operation::query()->create([
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppInit->id,
            'operation_type' => OperationType::TRANSFER,
            'operation_status' => OperationStatus::CREATED,
        ]);

        $transfer = TransferOperation::query()->create([
            'operation_id' => $operation->id,
            'project_id' => $project->id,
            'initiator_project_participant_id' => $ppInit->id,
            'sender_project_participant_id' => $ppInit->id,
            'receiver_project_participant_id' => $ppRecv->id,
            'transfer_target_type' => TransferTargetType::PERSONAL_BALANCE,
            'amount' => '7.00',
            'comment' => null,
            'operation_status' => OperationStatus::CREATED,
            'wallets_applied_at' => null,
        ]);

        $f = new EmployeeTransferFixture;
        $f->companyId = (int) $company->id;
        $f->ownerUser = $owner;
        $f->headPartnerUser = $headPartner;
        $f->employeeInitiatorUser = $empInit;
        $f->employeeReceiverUser = $empRecv;
        $f->transferId = (int) $transfer->id;
        $f->projectId = (int) $project->id;
        $f->ppHeadId = (int) $ppHead->id;

        return $f;
    }
}

/** @internal */
final class EmployeeTransferFixture
{
    public int $companyId = 0;

    public int $projectId = 0;

    public int $transferId = 0;

    public int $cpOwnerId = 0;

    public int $cpHeadId = 0;

    public int $ppHeadId = 0;

    public ?User $ownerUser = null;

    public ?User $headPartnerUser = null;

    public ?User $employeeInitiatorUser = null;

    public ?User $employeeReceiverUser = null;

    public ?User $sidePartnerUser = null;
}

/** @internal */
final class CustomerIncomesFixture
{
    public User $customerUser;

    public int $incomeCustomerApprovalId = 0;

    public int $incomeWaiting24Id = 0;
}
