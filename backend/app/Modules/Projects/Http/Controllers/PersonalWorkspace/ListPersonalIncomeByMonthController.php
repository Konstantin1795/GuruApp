<?php

declare(strict_types=1);

namespace App\Modules\Projects\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Enums\TransferTargetType;
use App\Modules\Workspaces\Support\PersonalWorkspaceRoleFilter;
use App\Support\Http\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Aggregates completed transfers to the user's personal balance by calendar month
 * (roles: performer workspace — employee, supplier, contractor).
 */
final class ListPersonalIncomeByMonthController
{
    public function __invoke(Request $request)
    {
        $userId = (int) $request->user()->id;

        $months = (int) $request->query('months', 6);
        if ($months < 1) {
            $months = 1;
        }
        if ($months > 24) {
            $months = 24;
        }

        $performerRoles = PersonalWorkspaceRoleFilter::fromQuery('performer');

        $start = Carbon::now()->startOfMonth()->subMonths($months - 1);

        $driver = DB::connection()->getDriverName();

        $baseQuery = DB::table('transfer_operations as t')
            ->join('project_participants as pp', 'pp.id', '=', 't.receiver_project_participant_id')
            ->join('counterparties as c', 'c.id', '=', 'pp.counterparty_id')
            ->where('c.user_id', $userId)
            ->whereIn('c.company_role_code', $performerRoles)
            ->where('t.transfer_target_type', TransferTargetType::PERSONAL_BALANCE->value)
            ->where('t.operation_status', OperationStatus::COMPLETED->value)
            ->where('t.updated_at', '>=', $start);

        $totalsByKey = match ($driver) {
            'pgsql' => (clone $baseQuery)
                ->selectRaw(
                    'EXTRACT(YEAR FROM t.updated_at)::int as y, EXTRACT(MONTH FROM t.updated_at)::int as m, SUM(t.amount) as total',
                )
                ->groupByRaw('EXTRACT(YEAR FROM t.updated_at), EXTRACT(MONTH FROM t.updated_at)')
                ->get(),
            'sqlite' => (clone $baseQuery)
                ->selectRaw(
                    "CAST(strftime('%Y', t.updated_at) AS int) as y, CAST(strftime('%m', t.updated_at) AS int) as m, SUM(t.amount) as total",
                )
                ->groupByRaw("strftime('%Y', t.updated_at), strftime('%m', t.updated_at)")
                ->get(),
            default => (clone $baseQuery)
                ->selectRaw('YEAR(t.updated_at) as y, MONTH(t.updated_at) as m, SUM(t.amount) as total')
                ->groupByRaw('YEAR(t.updated_at), MONTH(t.updated_at)')
                ->get(),
        };

        $totalsByKey = $totalsByKey
            ->keyBy(static fn ($row) => ((int) $row->y).'-'.str_pad((string) $row->m, 2, '0', STR_PAD_LEFT));

        $out = [];
        $periodTotal = '0.00';
        $cursor = $start->copy();

        for ($i = 0; $i < $months; $i++) {
            $y = (int) $cursor->year;
            $m = (int) $cursor->month;
            $key = $y.'-'.str_pad((string) $m, 2, '0', STR_PAD_LEFT);
            $row = $totalsByKey->get($key);
            $total = $row !== null
                ? number_format((float) $row->total, 2, '.', '')
                : '0.00';

            $out[] = [
                'year' => $y,
                'month' => $m,
                'total' => $total,
            ];

            $periodTotal = $this->addDecimalStrings($periodTotal, $total);
            $cursor->addMonth();
        }

        return ApiResponse::ok([
            'months' => $out,
            'total_for_period' => $periodTotal,
        ]);
    }

    private function addDecimalStrings(string $a, string $b): string
    {
        $ai = $this->decimalToInt($a);
        $bi = $this->decimalToInt($b);

        return $this->intToDecimal($ai + $bi);
    }

    private function decimalToInt(string $value): int
    {
        $value = trim($value);
        $negative = str_starts_with($value, '-');
        if ($negative) {
            $value = substr($value, 1);
        }
        [$whole, $fraction] = array_pad(explode('.', $value, 2), 2, '00');
        $fraction = str_pad(substr($fraction, 0, 2), 2, '0');

        $cents = ((int) $whole * 100) + (int) $fraction;

        return $negative ? -$cents : $cents;
    }

    private function intToDecimal(int $cents): string
    {
        $sign = $cents < 0 ? '-' : '';
        $abs = abs($cents);
        $whole = intdiv($abs, 100);
        $frac = $abs % 100;

        return sprintf('%s%d.%02d', $sign, $whole, $frac);
    }
}
