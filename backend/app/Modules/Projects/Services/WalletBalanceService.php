<?php

namespace App\Modules\Projects\Services;

use App\Modules\Projects\Models\ProjectParticipantWallet;

/**
 * Reads and prepares balance data for a participant wallet.
 * Foundation for future delta-accounting operations (ТЗ-05).
 *
 * @return array{
 *   personal_balance: string,
 *   personal_earned: string,
 *   personal_received: string,
 *   accountable_balance: string,
 *   accountable_received: string,
 *   accountable_spent: string,
 * }
 */
final class WalletBalanceService
{
    /**
     * @return array<string,string>
     */
    public function getBalances(ProjectParticipantWallet $wallet): array
    {
        return [
            'personal_balance'     => (string) $wallet->personal_balance,
            'personal_earned'      => (string) $wallet->personal_earned,
            'personal_received'    => (string) $wallet->personal_received,
            'accountable_balance'  => (string) $wallet->accountable_balance,
            'accountable_received' => (string) $wallet->accountable_received,
            'accountable_spent'    => (string) $wallet->accountable_spent,
        ];
    }
}
