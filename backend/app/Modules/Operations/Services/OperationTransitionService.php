<?php

namespace App\Modules\Operations\Services;

use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Enums\OperationType;
use App\Modules\Operations\Exceptions\InvalidOperationTransitionException;
use App\Modules\Operations\Models\Operation;
use App\Modules\Operations\Models\OperationStatusHistory;
use Illuminate\Support\Facades\DB;

/**
 * Validates and applies operation status transitions.
 * All transition rules live here — controllers and other services
 * must never mutate operation_status directly.
 */
final class OperationTransitionService
{
    /**
     * Allowed transitions map: current → list of reachable statuses.
     *
     * @var array<string, OperationStatus[]>
     */
    private const TRANSITIONS = [
        'CREATED' => [
            OperationStatus::PROJECT_HEAD_APPROVAL,
            OperationStatus::REJECTED,
        ],
        'PROJECT_HEAD_APPROVAL' => [
            OperationStatus::CUSTOMER_APPROVAL,
            OperationStatus::REJECTED,
        ],
        'CUSTOMER_APPROVAL' => [
            OperationStatus::WAITING_24_HOURS,
            OperationStatus::REJECTED,
        ],
        'WAITING_24_HOURS' => [
            OperationStatus::COMPLETED,
            OperationStatus::ROLLED_BACK,
        ],
        // Terminal states — no outgoing transitions
        'COMPLETED'   => [],
        'REJECTED'    => [],
        'ROLLED_BACK' => [],
    ];

    /**
     * @throws InvalidOperationTransitionException
     */
    public function transition(
        Operation $operation,
        OperationStatus $toStatus,
        ?int $changedByParticipantId = null,
    ): Operation {
        $fromStatus = $operation->operation_status;

        $this->assertAllowed($fromStatus, $toStatus, $operation->operation_type);

        DB::transaction(function () use ($operation, $fromStatus, $toStatus, $changedByParticipantId): void {
            $operation->update(['operation_status' => $toStatus]);

            OperationStatusHistory::query()->create([
                'operation_id'                    => $operation->id,
                'from_status'                     => $fromStatus,
                'to_status'                       => $toStatus,
                'changed_by_project_participant_id' => $changedByParticipantId,
            ]);
        });

        $operation->refresh();

        return $operation;
    }

    public function canTransition(OperationStatus $from, OperationStatus $to): bool
    {
        $allowed = self::TRANSITIONS[$from->value] ?? [];

        return in_array($to, $allowed, true);
    }

    /**
     * Returns all statuses reachable from the given status.
     *
     * @return OperationStatus[]
     */
    public function allowedTransitions(OperationStatus $from): array
    {
        return self::TRANSITIONS[$from->value] ?? [];
    }

    /**
     * @throws InvalidOperationTransitionException
     */
    private function assertAllowed(OperationStatus $from, OperationStatus $to, OperationType $operationType): void
    {
        if ($from->isTerminalForOperationType($operationType)) {
            throw new InvalidOperationTransitionException(
                "Operation is in terminal status [{$from->value}] and cannot be transitioned.",
            );
        }

        if (! $this->canTransition($from, $to)) {
            throw new InvalidOperationTransitionException(
                "Transition from [{$from->value}] to [{$to->value}] is not allowed.",
            );
        }
    }
}
