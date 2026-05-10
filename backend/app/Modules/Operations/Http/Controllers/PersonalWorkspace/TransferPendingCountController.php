<?php

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Services\TransferPendingActionCountService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class TransferPendingCountController
{
    public function __invoke(
        Request $request,
        TransferPendingActionCountService $pending,
    ) {
        $userId = (int) $request->user()->id;
        $count = $pending->countForPersonalWorkspace($userId);

        return ApiResponse::ok(['pending_action_count' => $count]);
    }
}
