<?php

namespace App\Modules\Operations\Services;

use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\Operation;
use App\Modules\Operations\Models\OperationStatusHistory;

/**
 * Centralised status queries and lifecycle helpers.
 * Stateless — no side-effects on operations.
 */
final class OperationStatusService
{
    public function __construct(
        private readonly OperationTransitionService $transitionService,
    ) {}

    /**
     * Full history for an operation, oldest first.
     *
     * @return OperationStatusHistory[]
     */
    public function history(Operation $operation): array
    {
        return $operation->statusHistory()->get()->all();
    }

    /**
     * Human-readable label for an operation status.
     */
    public function label(OperationStatus $status): string
    {
        return match ($status) {
            OperationStatus::CREATED               => 'Создана',
            OperationStatus::PROJECT_HEAD_APPROVAL => 'Ожидает подтверждения руководителя',
            OperationStatus::CUSTOMER_APPROVAL     => 'Ожидает подтверждения заказчика',
            OperationStatus::WAITING_24_HOURS      => 'Период ожидания 24 часа',
            OperationStatus::COMPLETED             => 'Завершена',
            OperationStatus::REJECTED              => 'Отклонена',
            OperationStatus::ROLLED_BACK           => 'Откат выполнен',
        };
    }

    /**
     * All statuses the given operation can move to next.
     *
     * @return OperationStatus[]
     */
    public function nextStatuses(Operation $operation): array
    {
        return $this->transitionService->allowedTransitions($operation->operation_status);
    }

    /**
     * Whether the operation is in a terminal status for its {@see Operation::$operation_type}
     * (e.g. Transfer: REJECTED is not terminal).
     */
    public function isTerminal(Operation $operation): bool
    {
        return $operation->operation_status->isTerminalForOperationType($operation->operation_type);
    }
}
