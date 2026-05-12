<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\TransferOperation;
use App\Modules\Operations\Services\TransferAvailableActionsService;
use App\Modules\Projects\Models\ProjectParticipant;
use Carbon\Carbon;
use Tests\TestCase;

final class TransferAvailableActionsPendingBadgeTest extends TestCase
{
    public function test_partner_initiator_created_is_pending_via_complete_immediate(): void
    {
        $svc = new TransferAvailableActionsService;
        $actor = new ProjectParticipant;
        $actor->forceFill([
            'id' => 10,
            'project_role_code' => ProjectRoleCode::PARTNER->value,
        ]);
        $initiator = new ProjectParticipant;
        $initiator->forceFill([
            'id' => 10,
            'project_role_code' => ProjectRoleCode::PARTNER->value,
        ]);
        $transfer = new TransferOperation([
            'initiator_project_participant_id' => 10,
            'operation_status' => OperationStatus::CREATED,
            'wallets_applied_at' => null,
        ]);
        $transfer->setRelation('initiator', $initiator);

        self::assertTrue($svc->hasPendingConfirmationAction($actor, $transfer));
    }

    public function test_waiting_24_hours_employee_initiator_is_not_pending_badge(): void
    {
        $svc = new TransferAvailableActionsService;
        $actor = new ProjectParticipant;
        $actor->forceFill([
            'id' => 5,
            'project_role_code' => ProjectRoleCode::EMPLOYEE->value,
        ]);
        $initiator = new ProjectParticipant;
        $initiator->forceFill([
            'id' => 5,
            'project_role_code' => ProjectRoleCode::EMPLOYEE->value,
        ]);
        $transfer = new TransferOperation([
            'initiator_project_participant_id' => 5,
            'operation_status' => OperationStatus::WAITING_24_HOURS,
            'wallets_applied_at' => Carbon::now(),
        ]);
        $transfer->setRelation('initiator', $initiator);

        self::assertFalse($svc->hasPendingConfirmationAction($actor, $transfer));
    }
}
