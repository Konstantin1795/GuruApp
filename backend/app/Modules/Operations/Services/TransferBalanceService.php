<?php

namespace App\Modules\Operations\Services;

use App\Modules\Operations\Enums\TransferTargetType;
use App\Modules\Projects\Models\ProjectParticipantWallet;
use Illuminate\Validation\ValidationException;

/**
 * Transfer wallet math — ТЗ-05.2 v3 §5.1–5.2.
 *
 * Источник списания всегда: sender.accountable_balance (+ accountable_spent).
 * Используем целые копейки/центы в расчётах; в БД — decimal string.
 * sender.personal_balance при переводе не меняется.
 */
final class TransferBalanceService
{
    public function applyTransfer(
        ProjectParticipantWallet $senderWallet,
        ProjectParticipantWallet $receiverWallet,
        TransferTargetType $targetType,
        string $amount,
    ): void {
        $amountCents = $this->toCents($amount);

        match ($targetType) {
            TransferTargetType::PERSONAL_BALANCE    => $this->applyPersonalTransfer($senderWallet, $receiverWallet, $amountCents),
            TransferTargetType::ACCOUNTABLE_BALANCE => $this->applyAccountableTransfer($senderWallet, $receiverWallet, $amountCents),
        };
    }

    public function revertTransfer(
        ProjectParticipantWallet $senderWallet,
        ProjectParticipantWallet $receiverWallet,
        TransferTargetType $targetType,
        string $amount,
    ): void {
        $amountCents = $this->toCents($amount);

        match ($targetType) {
            TransferTargetType::PERSONAL_BALANCE    => $this->revertPersonalTransfer($senderWallet, $receiverWallet, $amountCents),
            TransferTargetType::ACCOUNTABLE_BALANCE => $this->revertAccountableTransfer($senderWallet, $receiverWallet, $amountCents),
        };
    }

    /**
     * PERSONAL_BALANCE: зачисление на расчётный/личный баланс получателя (§5.2).
     */
    private function applyPersonalTransfer(
        ProjectParticipantWallet $senderWallet,
        ProjectParticipantWallet $receiverWallet,
        int $amountCents,
    ): void {
        $this->applySenderAccountableDebit($senderWallet, $amountCents);

        $receiverWallet->update([
            'personal_balance' => $this->fromCents(
                $this->walletBalanceToCents($receiverWallet->personal_balance) + $amountCents,
            ),
            'personal_received' => $this->fromCents(
                $this->walletBalanceToCents($receiverWallet->personal_received) + $amountCents,
            ),
        ]);
    }

    private function revertPersonalTransfer(
        ProjectParticipantWallet $senderWallet,
        ProjectParticipantWallet $receiverWallet,
        int $amountCents,
    ): void {
        $this->revertSenderAccountableDebit($senderWallet, $amountCents);

        $receiverWallet->update([
            'personal_balance' => $this->fromCents(
                $this->walletBalanceToCents($receiverWallet->personal_balance) - $amountCents,
            ),
            'personal_received' => $this->fromCents(
                $this->walletBalanceToCents($receiverWallet->personal_received) - $amountCents,
            ),
        ]);
    }

    /**
     * ACCOUNTABLE_BALANCE: зачисление на подотчётный баланс получателя (§5.1).
     */
    private function applyAccountableTransfer(
        ProjectParticipantWallet $senderWallet,
        ProjectParticipantWallet $receiverWallet,
        int $amountCents,
    ): void {
        $this->applySenderAccountableDebit($senderWallet, $amountCents);

        $receiverWallet->update([
            'accountable_balance' => $this->fromCents(
                $this->walletBalanceToCents($receiverWallet->accountable_balance) + $amountCents,
            ),
            'accountable_received' => $this->fromCents(
                $this->walletBalanceToCents($receiverWallet->accountable_received) + $amountCents,
            ),
        ]);
    }

    private function revertAccountableTransfer(
        ProjectParticipantWallet $senderWallet,
        ProjectParticipantWallet $receiverWallet,
        int $amountCents,
    ): void {
        $this->revertSenderAccountableDebit($senderWallet, $amountCents);

        $receiverWallet->update([
            'accountable_balance' => $this->fromCents(
                $this->walletBalanceToCents($receiverWallet->accountable_balance) - $amountCents,
            ),
            'accountable_received' => $this->fromCents(
                $this->walletBalanceToCents($receiverWallet->accountable_received) - $amountCents,
            ),
        ]);
    }

    private function applySenderAccountableDebit(ProjectParticipantWallet $senderWallet, int $amountCents): void
    {
        $balance = $this->walletBalanceToCents($senderWallet->accountable_balance) - $amountCents;
        $spent = $this->walletBalanceToCents($senderWallet->accountable_spent) + $amountCents;

        $senderWallet->update([
            'accountable_balance' => $this->fromCents($balance),
            'accountable_spent'   => $this->fromCents($spent),
        ]);
    }

    private function revertSenderAccountableDebit(ProjectParticipantWallet $senderWallet, int $amountCents): void
    {
        $balance = $this->walletBalanceToCents($senderWallet->accountable_balance) + $amountCents;
        $spent = $this->walletBalanceToCents($senderWallet->accountable_spent) - $amountCents;

        $senderWallet->update([
            'accountable_balance' => $this->fromCents($balance),
            'accountable_spent'   => $this->fromCents($spent),
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
        $sign     = $cents < 0 ? '-' : '';
        $absolute = abs($cents);
        $whole    = intdiv($absolute, 100);
        $fraction = $absolute % 100;

        return sprintf('%s%d.%02d', $sign, $whole, $fraction);
    }
}
