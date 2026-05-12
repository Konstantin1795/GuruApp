<?php

namespace App\Modules\Projects\Services;

final class PriceListPricing
{
    /**
     * @return array{profit_amount: string, profit_percent: string|null}
     */
    public static function profit(string $recipientUnitPrice, string $customerUnitPrice): array
    {
        $recipientUnitPrice = self::normalizeMoney($recipientUnitPrice);
        $customerUnitPrice = self::normalizeMoney($customerUnitPrice);

        $profit = bcsub($customerUnitPrice, $recipientUnitPrice, 2);

        $percent = null;
        if (bccomp($recipientUnitPrice, '0', 2) > 0) {
            $percent = bcdiv(bcmul($profit, '100', 4), $recipientUnitPrice, 2);
        }

        return [
            'profit_amount' => $profit,
            'profit_percent' => $percent,
        ];
    }

    public static function normalizeMoney(string $value): string
    {
        $value = trim($value);
        if ($value === '') {
            return '0.00';
        }

        return number_format((float) $value, 2, '.', '');
    }
}
