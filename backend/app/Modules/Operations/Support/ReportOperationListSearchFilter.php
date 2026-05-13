<?php

declare(strict_types=1);

namespace App\Modules\Operations\Support;

use Illuminate\Database\Eloquent\Builder;

/**
 * Опциональный query-параметр {@code search} для списка отчётов проекта (ТЗ-10C.1).
 */
final class ReportOperationListSearchFilter
{
    public static function apply(Builder $query, string $search): void
    {
        $s = trim($search);
        if ($s === '') {
            return;
        }

        $escaped = addcslashes($s, '%_\\');
        $like = '%'.$escaped.'%';

        $query->where(function (Builder $q) use ($like, $s): void {
            $q->where('operation_number', 'like', $like)
                ->orWhere('customer_total_amount', 'like', $like)
                ->orWhere('recipient_amount', 'like', $like)
                ->orWhere('profit_amount', 'like', $like);

            if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $s) === 1) {
                $q->orWhereDate('operation_date', $s);
            }
        });
    }
}
