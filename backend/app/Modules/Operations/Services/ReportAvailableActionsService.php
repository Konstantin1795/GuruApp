<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Projects\Models\ProjectParticipant;

final class ReportAvailableActionsService
{
    /** Ключи, которые считаются «ожидают подтверждения» для бейджа pending (согласовано с ТЗ-10C). */
    public const PENDING_BADGE_ACTION_KEYS = [
        'submit',
        'approve_supervisor',
        'reject_supervisor',
        'approve_project_head',
        'reject_project_head',
        'approve_customer',
        'reject_customer',
        'rollback_completed',
    ];

    public function forParticipant(ProjectParticipant $actor, ReportOperation $report): array
    {
        $s = $report->operation_status;
        $isInitiator = (int) $report->initiator_project_participant_id === (int) $actor->id;
        $isCustomer = (int) $report->customer_project_participant_id === (int) $actor->id;
        $isHead = $actor->project_role_code === \App\Modules\Dictionaries\Enums\ProjectRoleCode::PROJECT_HEAD->value;
        $isSupervisor = $actor->project_role_code === \App\Modules\Dictionaries\Enums\ProjectRoleCode::SUPERVISOR->value;

        $actions = [];

        if ($s === OperationStatus::CREATED && $isInitiator) {
            $actions['submit'] = true;
        }

        if ($s === OperationStatus::SUPERVISOR_APPROVAL && $isSupervisor) {
            $actions['approve_supervisor'] = true;
            $actions['reject_supervisor'] = true;
        }

        if ($s === OperationStatus::PROJECT_HEAD_APPROVAL && $isHead) {
            $actions['approve_project_head'] = true;
            $actions['reject_project_head'] = true;
        }

        if ($s === OperationStatus::CUSTOMER_APPROVAL && $isCustomer) {
            $actions['approve_customer'] = true;
            $actions['reject_customer'] = true;
        }

        if ($s === OperationStatus::WAITING_24_HOURS && $isHead) {
            $actions['complete_waiting'] = true;
        }

        if ($s === OperationStatus::COMPLETED && $isHead) {
            $actions['rollback_completed'] = true;
        }

        return $actions;
    }

    public function hasPendingConfirmationAction(ProjectParticipant $actor, ReportOperation $report): bool
    {
        $actions = $this->forParticipant($actor, $report);
        foreach (self::PENDING_BADGE_ACTION_KEYS as $key) {
            if (! empty($actions[$key])) {
                return true;
            }
        }

        return false;
    }
}
