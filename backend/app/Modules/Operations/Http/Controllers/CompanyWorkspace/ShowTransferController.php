<?php

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Resources\TransferOperationResource;
use App\Modules\Operations\Services\OperationVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ShowTransferController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        OperationVisibilityService $operationVisibility,
        int $companyId,
        int $projectId,
        int $transferId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessCompanyProject($userId, $companyId, $projectId);

        $transfer = $operationVisibility
            ->assertCanViewTransfer($project, $userId, $transferId)
            ->load([
                'sender.counterparty.user',
                'receiver.counterparty.user',
                'operation.statusHistory',
            ]);

        return ApiResponse::ok([
            'transfer' => (new TransferOperationResource($transfer))->resolve(),
        ]);
    }
}
