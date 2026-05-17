<?php

declare(strict_types=1);

namespace App\Modules\Workspaces\Http\Controllers;

use App\Modules\Workspaces\Services\CompanyDashboardAnalyticsService;
use App\Support\Http\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

final class GetCompanyDashboardOverpaymentDetailController
{
    public function __invoke(
        Request $request,
        CompanyDashboardAnalyticsService $service,
        int $companyId,
    ) {
        $projectId = (int) $request->query('project_id', '0');
        if ($projectId <= 0) {
            throw ValidationException::withMessages([
                'project_id' => ['project_id is required and must be a positive integer.'],
            ]);
        }

        $month = $request->query('month');
        $month = is_string($month) && preg_match('/^\d{4}-\d{2}$/', $month) ? $month : null;

        $payload = $service->overpaymentProjectDetail(
            $companyId,
            (int) $request->user()->id,
            $projectId,
            $month,
            Carbon::now('UTC'),
        );

        return ApiResponse::ok($payload);
    }
}
