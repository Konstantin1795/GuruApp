<?php

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Services\TransferPendingActionCountService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class TransferPendingCountController
{
    public function __invoke(
        Request $request,
        TransferPendingActionCountService $pending,
        int $companyId,
    ) {
        $userId = (int) $request->user()->id;
        $count = $pending->countForCompanyWorkspace($userId, $companyId);

        return ApiResponse::ok(['pending_action_count' => $count]);
    }
}
