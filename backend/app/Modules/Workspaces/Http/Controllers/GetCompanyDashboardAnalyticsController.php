<?php

declare(strict_types=1);

namespace App\Modules\Workspaces\Http\Controllers;

use App\Modules\Workspaces\Services\CompanyDashboardAnalyticsService;
use App\Support\Http\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\Request;

final class GetCompanyDashboardAnalyticsController
{
    public function __invoke(
        Request $request,
        CompanyDashboardAnalyticsService $service,
        int $companyId,
    ) {
        $month = $request->query('month');
        $month = is_string($month) && preg_match('/^\d{4}-\d{2}$/', $month) ? $month : null;

        return ApiResponse::ok(
            $service->build($companyId, (int) $request->user()->id, $month, Carbon::now('UTC')),
        );
    }
}
