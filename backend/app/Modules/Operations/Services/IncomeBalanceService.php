<?php

namespace App\Modules\Operations\Services;

use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Projects\Models\ProjectParticipantWallet;
use App\Modules\Projects\Services\WalletService;
use Illuminate\Validation\ValidationException;

/**
 * ТЗ-06: начисление поступления на подотчёт Заказчика и Руководителя проекта.
 *
 * REPORT (когда появится) — отдельные сервисы lifecycle/balance; не смешивать дельты отчёта с INCOME здесь.
 */
final class IncomeBalanceService
{
    public function __construct(
        private readonly WalletService $walletService,
    ) {}

    /**
     * @throws ValidationException
     */
    public function applyIncomeDeltas(IncomeOperation $income): void
    {
        if ($income->wallets_applied_at !== null) {
            throw ValidationException::withMessages([
                'income' => ['Финансовые дельты уже применены.'],
            ]);
        }

        $amount = (string) $income->amount;
        $customer = $income->customer()->whereKey($income->customer_project_participant_id)->firstOrFail();
        $head = $income->projectHead()->whereKey($income->project_head_project_participant_id)->firstOrFail();

        $cw = $this->walletService->ensureWallet($customer);
        $hw = $this->walletService->ensureWallet($head);

        $cw = $cw->newQuery()->whereKey($cw->id)->lockForUpdate()->firstOrFail();
        $hw = $hw->newQuery()->whereKey($hw->id)->lockForUpdate()->firstOrFail();

        $this->creditAccountable($cw, $amount);
        $this->creditAccountable($hw, $amount);
    }

    /**
     * @throws ValidationException
     */
    public function revertIncomeDeltas(IncomeOperation $income): void
    {
        if ($income->wallets_applied_at === null) {
            throw ValidationException::withMessages([
                'income' => ['Нечего откатывать: дельты не применялись.'],
            ]);
        }

        $amount = (string) $income->amount;
        $customer = $income->customer()->whereKey($income->customer_project_participant_id)->firstOrFail();
        $head = $income->projectHead()->whereKey($income->project_head_project_participant_id)->firstOrFail();

        $cw = $this->walletService->ensureWallet($customer);
        $hw = $this->walletService->ensureWallet($head);

        $cw = $cw->newQuery()->whereKey($cw->id)->lockForUpdate()->firstOrFail();
        $hw = $hw->newQuery()->whereKey($hw->id)->lockForUpdate()->firstOrFail();

        $this->debitAccountableReceived($cw, $amount);
        $this->debitAccountableReceived($hw, $amount);
    }

    private function creditAccountable(ProjectParticipantWallet $wallet, string $amount): void
    {
        $cents = $this->toCents($amount);
        $wallet->update([
            'accountable_balance' => $this->fromCents($this->walletBalanceToCents($wallet->accountable_balance) + $cents),
            'accountable_received' => $this->fromCents($this->walletBalanceToCents($wallet->accountable_received) + $cents),
        ]);
    }

    private function debitAccountableReceived(ProjectParticipantWallet $wallet, string $amount): void
    {
        $cents = $this->toCents($amount);
        $wallet->update([
            'accountable_balance' => $this->fromCents($this->walletBalanceToCents($wallet->accountable_balance) - $cents),
            'accountable_received' => $this->fromCents($this->walletBalanceToCents($wallet->accountable_received) - $cents),
        ]);
    }

    private function walletBalanceToCents(mixed $raw): int
    {
        if ($raw === null) {
            return 0;
        }
        if (is_float($raw)) {
            return $this->toCents(sprintf('%.2f', $raw));
        }

        $s = trim((string) $raw);
        if ($s === '') {
            return 0;
        }

        return $this->toCents($s);
    }

    /**
     * @throws ValidationException when the format is invalid
     */
    private function toCents(string $amount): int
    {
        $value = trim($amount);
        $negative = str_starts_with($value, '-');
        if ($negative) {
            $value = substr($value, 1);
        }

        if (! preg_match('/^\d+(\.\d{1,2})?$/', $value)) {
            throw ValidationException::withMessages([
                'amount' => ['Некорректный формат суммы.'],
            ]);
        }

        [$whole, $fraction] = array_pad(explode('.', $value, 2), 2, '0');
        $fraction = str_pad(substr($fraction, 0, 2), 2, '0');

        $cents = ((int) $whole * 100) + (int) $fraction;

        return $negative ? -$cents : $cents;
    }

    private function fromCents(int $cents): string
    {
        $sign = $cents < 0 ? '-' : '';
        $absolute = abs($cents);
        $whole = intdiv($absolute, 100);
        $fraction = $absolute % 100;

        return sprintf('%s%d.%02d', $sign, $whole, $fraction);
    }
}
