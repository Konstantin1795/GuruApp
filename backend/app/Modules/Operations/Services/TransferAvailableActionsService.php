<?php

namespace App\Modules\Operations\Services;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\TransferOperation;
use App\Modules\Projects\Models\ProjectParticipant;

/**
 * Какие POST-действия по переводу доступны участнику (без выполнения).
 * Синхронно с TransferLifecycleService.
 */
final class TransferAvailableActionsService
{
    /**
     * Какие флаги из forParticipant() участвуют в бейдже «ожидают от вас шага / подтверждения».
     *
     * Не включаем: complete_immediate (опция инициатора), reset_approval (снятие с рассмотрения),
     * вмешательство в WAITING_24_HOURS (процесс идёт по таймеру), rollback/return completed (коррективы).
     * При добавлении Отчёта/Поступления/согласования заказчика — дополнять этот список.
     */
    private const PENDING_BADGE_ACTION_KEYS = [
        'approve_project_head',
        'reject_project_head',
        'submit_for_approval',
    ];

    /**
     * @return array<string, bool>
     */
    public function forParticipant(ProjectParticipant $actor, TransferOperation $transfer): array
    {
        $transfer->loadMissing('initiator');
        $s = $transfer->operation_status;
        $ar = $actor->project_role_code;
        $isInitiator = (int) $transfer->initiator_project_participant_id === (int) $actor->id;
        $initiator = $transfer->initiator;
        $ir = $initiator?->project_role_code;
        $deltasApplied = $transfer->wallets_applied_at !== null;

        $base = array_fill_keys([
            'approve_project_head',
            'reject_project_head',
            'reset_approval',
            'submit_for_approval',
            'complete_immediate',
            'return_to_created',
            'return_to_project_head_approval',
            'complete_waiting',
            'rollback_completed',
            'return_completed_to_project_head_approval',
        ], false);

        if ($s === OperationStatus::PROJECT_HEAD_APPROVAL) {
            if ($ar === ProjectRoleCode::PROJECT_HEAD->value && ! $deltasApplied) {
                $base['approve_project_head'] = true;
                $base['reject_project_head'] = true;
            }
            if ($ar === ProjectRoleCode::EMPLOYEE->value && $isInitiator && ! $deltasApplied) {
                $base['reset_approval'] = true;
            }
        }

        if ($s === OperationStatus::CREATED) {
            if (! $deltasApplied) {
                if ($ar === ProjectRoleCode::EMPLOYEE->value && $isInitiator) {
                    $base['submit_for_approval'] = true;
                }
                if ($isInitiator && in_array($ar, [
                    ProjectRoleCode::PROJECT_HEAD->value,
                    ProjectRoleCode::PARTNER->value,
                ], true)) {
                    $base['complete_immediate'] = true;
                }
            }
        }

        if ($s === OperationStatus::WAITING_24_HOURS && $deltasApplied) {
            if ($ar === ProjectRoleCode::EMPLOYEE->value && $isInitiator) {
                $base['return_to_created'] = true;
            }
            if ($ar === ProjectRoleCode::PROJECT_HEAD->value) {
                $base['return_to_project_head_approval'] = true;
                $base['complete_waiting'] = true;
            }
        }

        if ($s === OperationStatus::COMPLETED && $deltasApplied) {
            if ($ir === ProjectRoleCode::EMPLOYEE->value && $ar === ProjectRoleCode::PROJECT_HEAD->value) {
                $base['return_completed_to_project_head_approval'] = true;
            }

            if ($ir !== null && in_array($ir, [
                ProjectRoleCode::PROJECT_HEAD->value,
                ProjectRoleCode::PARTNER->value,
            ], true)) {
                if ($ir === ProjectRoleCode::PROJECT_HEAD->value && $isInitiator && $ar === ProjectRoleCode::PROJECT_HEAD->value) {
                    $base['rollback_completed'] = true;
                }
                if ($ir === ProjectRoleCode::PARTNER->value) {
                    if ($isInitiator || $ar === ProjectRoleCode::PROJECT_HEAD->value) {
                        $base['rollback_completed'] = true;
                    }
                }
            }
        }

        return $base;
    }

    public function hasAnyAction(ProjectParticipant $actor, TransferOperation $transfer): bool
    {
        foreach ($this->forParticipant($actor, $transfer) as $allowed) {
            if ($allowed) {
                return true;
            }
        }

        return false;
    }

    /**
     * Есть ли у участника действие, из‑за которого операция «ждёт» именно его реакции
     * для движения по процессу (согласование / повторная отправка сотрудником), а не опциональная кнопка.
     */
    public function hasPendingConfirmationAction(ProjectParticipant $actor, TransferOperation $transfer): bool
    {
        $map = $this->forParticipant($actor, $transfer);

        foreach (self::PENDING_BADGE_ACTION_KEYS as $key) {
            if (($map[$key] ?? false) === true) {
                return true;
            }
        }

        return false;
    }
}
