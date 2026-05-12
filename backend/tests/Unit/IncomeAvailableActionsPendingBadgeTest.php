<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Services\IncomeAvailableActionsService;
use App\Modules\Projects\Models\ProjectParticipant;
use Carbon\Carbon;
use Tests\TestCase;

final class IncomeAvailableActionsPendingBadgeTest extends TestCase
{
    public function test_initiator_in_customer_approval_is_not_pending_badge_reset_is_optional(): void
    {
        $svc = new IncomeAvailableActionsService;
        $initiator = new ProjectParticipant;
        $initiator->forceFill([
            'id' => 20,
            'project_role_code' => ProjectRoleCode::PROJECT_HEAD->value,
        ]);
        $income = new IncomeOperation([
            'initiator_project_participant_id' => 20,
            'customer_project_participant_id' => 99,
            'operation_status' => OperationStatus::CUSTOMER_APPROVAL,
            'wallets_applied_at' => Carbon::now(),
        ]);
        $income->setRelation('initiator', $initiator);

        self::assertTrue($svc->forParticipant($initiator, $income)['reset_approval']);
        self::assertFalse($svc->hasPendingConfirmationAction($initiator, $income));
    }

    public function test_customer_in_customer_approval_is_pending_badge(): void
    {
        $svc = new IncomeAvailableActionsService;
        $customer = new ProjectParticipant;
        $customer->forceFill([
            'id' => 99,
            'project_role_code' => ProjectRoleCode::CUSTOMER->value,
        ]);
        $initiator = new ProjectParticipant;
        $initiator->forceFill([
            'id' => 20,
            'project_role_code' => ProjectRoleCode::PROJECT_HEAD->value,
        ]);
        $income = new IncomeOperation([
            'initiator_project_participant_id' => 20,
            'customer_project_participant_id' => 99,
            'operation_status' => OperationStatus::CUSTOMER_APPROVAL,
            'wallets_applied_at' => Carbon::now(),
        ]);
        $income->setRelation('initiator', $initiator);

        self::assertTrue($svc->hasPendingConfirmationAction($customer, $income));
    }
}
