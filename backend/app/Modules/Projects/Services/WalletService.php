<?php

namespace App\Modules\Projects\Services;

use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Models\ProjectParticipantWallet;

/**
 * Orchestration layer for wallet operations.
 * Currently handles wallet provisioning only.
 * Transaction coordination (deposits, transfers) will be added in ТЗ-05.
 */
final class WalletService
{
    public function __construct(
        private readonly WalletFactoryService $factory,
        private readonly WalletBalanceService $balance,
    ) {}

    /**
     * Ensure the participant has a wallet (create if missing).
     */
    public function ensureWallet(ProjectParticipant $participant): ProjectParticipantWallet
    {
        return $this->factory->createForParticipant($participant);
    }

    /**
     * @return array<string,string>
     */
    public function getBalanceSummary(ProjectParticipantWallet $wallet): array
    {
        return $this->balance->getBalances($wallet);
    }
}
