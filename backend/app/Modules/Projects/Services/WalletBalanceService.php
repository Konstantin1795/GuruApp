<?php

namespace App\Modules\Projects\Services;

use App\Modules\Projects\Models\ProjectParticipantWallet;

/**
 * Чтение среза полей кошелька участника (без проведения дельт и без бизнес-правил ТЗ).
 *
 * Любая арифметика балансов по операциям — в {@see \App\Modules\Operations\Services\TransferBalanceService},
 * {@see \App\Modules\Operations\Services\IncomeBalanceService} и связанных lifecycle-сервисах.
 * Снимки/проводки по REPORT — в отдельных сервисах после ТЗ-10C, не в этом read-only слое.
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
