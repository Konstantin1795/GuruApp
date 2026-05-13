<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Modules\Projects\Services\PriceListPricing;
use PHPUnit\Framework\TestCase;

final class PriceListPricingNormalizeTest extends TestCase
{
    public function test_normalize_money_trims_and_formats_two_decimals(): void
    {
        self::assertSame('10.50', PriceListPricing::normalizeMoney('  10.5  '));
    }

    public function test_normalize_money_empty_string_is_zero(): void
    {
        self::assertSame('0.00', PriceListPricing::normalizeMoney(''));
    }

    public function test_profit_uses_string_math_not_throw_for_typical_prices(): void
    {
        $p = PriceListPricing::profit('10.00', '12.00');
        self::assertSame('2.00', $p['profit_amount']);
        self::assertSame('20.00', $p['profit_percent']);
    }
}
