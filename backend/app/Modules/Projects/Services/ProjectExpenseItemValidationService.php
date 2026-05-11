<?php

namespace App\Modules\Projects\Services;

use App\Modules\Companies\Models\Counterparty;
use Illuminate\Validation\ValidationException;

/**
 * ТЗ-10A: валидация долей и контрагентов для статей расходов.
 */
final class ProjectExpenseItemValidationService
{
    /**
     * @param  array<int, array{counterparty_id: int|string, percent: mixed}>  $profitShares
     * @param  array<int, array{counterparty_id: int|string, percent: mixed}>  $markupShares
     */
    public function validate(
        int $companyId,
        array $profitShares,
        bool $markupEnabled,
        mixed $markupPercent,
        array $markupShares,
    ): void {
        $this->validateShareBlock('profit_shares', $profitShares, true);
        if ($markupEnabled) {
            $markupPercentNorm = $this->normalizePercentField('markup_percent', $markupPercent, allowHundred: true);
            if ($markupPercentNorm === null) {
                throw ValidationException::withMessages([
                    'markup_percent' => ['Укажите процент наценки с точностью до двух знаков после запятой.'],
                ]);
            }
            $this->validateShareBlock('markup_shares', $markupShares, true);
        } else {
            if ($markupShares !== []) {
                throw ValidationException::withMessages([
                    'markup_shares' => ['При выключенной наценке блок долей наценки не передаётся.'],
                ]);
            }
        }

        $allCpIds = [];
        foreach ($profitShares as $row) {
            $allCpIds[] = (int) $row['counterparty_id'];
        }
        if ($markupEnabled) {
            foreach ($markupShares as $row) {
                $allCpIds[] = (int) $row['counterparty_id'];
            }
        }
        $this->assertCounterpartiesBelongToCompany(array_values(array_unique($allCpIds)), $companyId);
    }

    /** Нормализация процента доли (после успешной {@see validate()}). */
    public function normalizePercentForShare(mixed $value): string
    {
        $norm = $this->normalizePercentField('percent', $value, allowHundred: true);
        if ($norm === null) {
            throw ValidationException::withMessages([
                'percent' => ['Некорректный процент доли.'],
            ]);
        }

        return $norm;
    }

    /** Нормализация общего процента наценки. */
    public function normalizeMarkupPercentValue(mixed $value): string
    {
        $norm = $this->normalizePercentField('markup_percent', $value, allowHundred: true);
        if ($norm === null) {
            throw ValidationException::withMessages([
                'markup_percent' => ['Некорректный процент наценки.'],
            ]);
        }

        return $norm;
    }

    /**
     * @param  array<int, array{counterparty_id: int|string, percent: mixed}>  $rows
     */
    private function validateShareBlock(string $key, array $rows, bool $requireAtLeastOne): void
    {
        if ($requireAtLeastOne && $rows === []) {
            throw ValidationException::withMessages([
                $key => ['Добавьте хотя бы одного получателя.'],
            ]);
        }

        $seen = [];
        $sum = '0.00';
        foreach ($rows as $i => $row) {
            $cpId = (int) ($row['counterparty_id'] ?? 0);
            if ($cpId <= 0) {
                throw ValidationException::withMessages([
                    "{$key}.{$i}.counterparty_id" => ['Укажите контрагента.'],
                ]);
            }
            if (isset($seen[$cpId])) {
                throw ValidationException::withMessages([
                    $key => ['Один контрагент не может быть указан дважды в одном блоке долей.'],
                ]);
            }
            $seen[$cpId] = true;

            $norm = $this->normalizePercentField("{$key}.{$i}.percent", $row['percent'] ?? null, allowHundred: true);
            if ($norm === null) {
                throw ValidationException::withMessages([
                    "{$key}.{$i}.percent" => ['Укажите долю с точностью до двух знаков после запятой (шаг 0,01%).'],
                ]);
            }
            $sum = bcadd($sum, $norm, 2);
        }

        if (bccomp($sum, '100.00', 2) !== 0) {
            throw ValidationException::withMessages([
                $key => ['Сумма долей должна быть ровно 100,00%.'],
            ]);
        }
    }

    /**
     * @return non-empty-string|null normalized "12.34" or null if invalid
     */
    private function normalizePercentField(string $field, mixed $value, bool $allowHundred): ?string
    {
        if ($value === null) {
            return null;
        }
        $raw = is_string($value) ? trim($value) : (is_numeric($value) ? (string) $value : '');
        if ($raw === '') {
            return null;
        }
        if (! preg_match('/^\d{1,3}(\.\d{1,2})?$/', $raw)) {
            return null;
        }
        $parts = explode('.', $raw, 2);
        $int = $parts[0];
        $frac = isset($parts[1]) ? str_pad($parts[1], 2, '0', STR_PAD_RIGHT) : '00';
        if (strlen($frac) > 2) {
            return null;
        }
        $norm = $int.'.'.$frac;

        if (bccomp($norm, '0.00', 2) <= 0) {
            return null;
        }
        $max = $allowHundred ? '100.00' : '99.99';
        if (bccomp($norm, $max, 2) > 0) {
            return null;
        }

        return $norm;
    }

    /** @param  array<int, int>  $counterpartyIds */
    private function assertCounterpartiesBelongToCompany(array $counterpartyIds, int $companyId): void
    {
        if ($counterpartyIds === []) {
            return;
        }

        $count = Counterparty::query()
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->whereIn('id', $counterpartyIds)
            ->count();

        if ($count !== count(array_unique($counterpartyIds))) {
            throw ValidationException::withMessages([
                'counterparty_id' => ['Один или несколько контрагентов недоступны для этой компании.'],
            ]);
        }
    }
}
