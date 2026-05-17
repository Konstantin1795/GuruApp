<?php

declare(strict_types=1);

namespace App\Modules\Workspaces\Http\Controllers;

use App\Modules\Workspaces\Services\CompanyDashboardAnalyticsService;
use App\Support\Http\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

final class GetCompanyDashboardAnalyticsOperationsController
{
    public function __invoke(
        Request $request,
        CompanyDashboardAnalyticsService $service,
        int $companyId,
    ) {
        $metric = (string) $request->query('metric', '');
        if (! in_array($metric, ['income', 'debt', 'overpayment'], true)) {
            throw ValidationException::withMessages([
                'metric' => ['metric must be one of: income, debt, overpayment.'],
            ]);
        }

        $month = $request->query('month');
        $month = is_string($month) && preg_match('/^\d{4}-\d{2}$/', $month) ? $month : null;

        $items = $service->listOperations(
            $companyId,
            (int) $request->user()->id,
            $metric,
            $month,
            Carbon::now('UTC'),
        );

        return ApiResponse::ok(['items' => $items]);
    }
}
