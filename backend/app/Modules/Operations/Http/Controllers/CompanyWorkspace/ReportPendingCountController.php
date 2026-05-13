<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Services\ReportPendingActionCountService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ReportPendingCountController
{
    public function __invoke(
        Request $request,
        ReportPendingActionCountService $pending,
        int $companyId,
    ) {
        $userId = (int) $request->user()->id;
        $count = $pending->countForCompanyWorkspace($userId, $companyId);

        return ApiResponse::ok(['pending_action_count' => $count]);
    }
}
