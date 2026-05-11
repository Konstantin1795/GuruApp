<?php

namespace App\Modules\Operations\Services;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Projects\Models\ProjectParticipant;

/**
 * ТЗ-06 §18.4: доступные действия по поступлению.
 */
final class IncomeAvailableActionsService
{
    /** Для бейджа pending-count (ТЗ §18.5, ТЗ-06.1). */
    private const PENDING_BADGE_KEYS = [
        'approve_customer',
        'reject_customer',
        'submit_to_customer_approval',
        'reset_approval',
    ];

    /**
     * @return array<string, bool>
     */
    public function forParticipant(ProjectParticipant $actor, IncomeOperation $income): array
    {
        $income->loadMissing('initiator');

        $s = $income->operation_status;
        $ar = $actor->project_role_code;
        $isInitiator = (int) $income->initiator_project_participant_id === (int) $actor->id;
        $initiator = $income->initiator;
        $ir = $initiator?->project_role_code;
        $applied = $income->wallets_applied_at !== null;

        $base = array_fill_keys([
            'approve_customer',
            'reject_customer',
            'return_to_customer_approval',
            'complete_waiting',
            'rollback_completed',
            'submit_to_customer_approval',
            'reset_approval',
        ], false);

        $isCustomerActor = $ar === ProjectRoleCode::CUSTOMER->value
            && (int) $actor->id === (int) $income->customer_project_participant_id;

        if ($s === OperationStatus::CUSTOMER_APPROVAL && $applied) {
            if ($isCustomerActor) {
                $base['approve_customer'] = true;
                $base['reject_customer'] = true;
            }
            if ($isInitiator) {
                $base['reset_approval'] = true;
            }
        }

        if ($s === OperationStatus::WAITING_24_HOURS) {
            if ($isCustomerActor) {
                $base['return_to_customer_approval'] = true;
            }
            if ($ar === ProjectRoleCode::PROJECT_HEAD->value) {
                $base['complete_waiting'] = true;
            }
        }

        if ($s === OperationStatus::COMPLETED && $applied) {
            if ($ir === ProjectRoleCode::PROJECT_HEAD->value && $isInitiator && $ar === ProjectRoleCode::PROJECT_HEAD->value) {
                $base['rollback_completed'] = true;
            }
            if ($ir === ProjectRoleCode::PARTNER->value) {
                if (($isInitiator && $ar === ProjectRoleCode::PARTNER->value)
                    || $ar === ProjectRoleCode::PROJECT_HEAD->value) {
                    $base['rollback_completed'] = true;
                }
            }
        }

        if ($s === OperationStatus::CREATED && ! $applied && $isInitiator) {
            $base['submit_to_customer_approval'] = true;
        }

        return $base;
    }

    public function hasPendingConfirmationAction(ProjectParticipant $actor, IncomeOperation $income): bool
    {
        $map = $this->forParticipant($actor, $income);

        foreach (self::PENDING_BADGE_KEYS as $key) {
            if (($map[$key] ?? false) === true) {
                return true;
            }
        }

        return false;
    }
}
