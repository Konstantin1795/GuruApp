<?php

namespace App\Modules\Operations\Enums;

enum OperationStatus: string
{
    /** Newly created, awaiting first approval. */
    case CREATED                = 'CREATED';

    /** Pending approval by the project head (PROJECT_HEAD). */
    case PROJECT_HEAD_APPROVAL  = 'PROJECT_HEAD_APPROVAL';

    /** Pending approval by the customer (CUSTOMER). */
    case CUSTOMER_APPROVAL      = 'CUSTOMER_APPROVAL';

    /** Both parties approved; 24-hour rollback window is open. */
    case WAITING_24_HOURS       = 'WAITING_24_HOURS';

    /** Successfully completed; balances finalised. */
    case COMPLETED              = 'COMPLETED';

    /** Rejected at any approval stage; no balance change. */
    case REJECTED               = 'REJECTED';

    /** Rolled back during the 24-hour window; balances reversed. */
    case ROLLED_BACK            = 'ROLLED_BACK';

    /**
     * Default terminality for types that follow the generic lifecycle map
     * ({@see OperationTransitionService}) and as fallback for Income/Report until overridden.
     */
    public function isTerminal(): bool
    {
        return match ($this) {
            self::COMPLETED, self::REJECTED, self::ROLLED_BACK => true,
            default => false,
        };
    }

    /**
     * Terminality for a concrete operation type. Transfer treats REJECTED as non-terminal
     * (ТЗ-05.2: PROJECT_HEAD_APPROVAL → REJECTED → CREATED). Income/Report use {@see isTerminal()}
     * until their policies diverge.
     */
    public function isTerminalForOperationType(OperationType $type): bool
    {
        return match ($type) {
            OperationType::TRANSFER => match ($this) {
                self::COMPLETED, self::ROLLED_BACK => true,
                default => false,
            },
            OperationType::INCOME => match ($this) {
                self::COMPLETED => true,
                default => false,
            },
            OperationType::REPORT => $this->isTerminal(),
        };
    }
}
