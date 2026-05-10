<?php

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesProjectParticipant;
use App\Modules\Operations\Http\Resources\TransferOperationResource;
use App\Modules\Operations\Services\OperationVisibilityService;
use App\Modules\Operations\Services\TransferLifecycleService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class TransferSubmitForApprovalController
{
    use ResolvesProjectParticipant;

    public function __invoke(
        Request $request,
        TransferLifecycleService $lifecycle,
        ProjectVisibilityService $projectVisibility,
        OperationVisibilityService $operationVisibility,
        int $companyId,
        int $projectId,
        int $transferId,
    ) {
        $user = $request->user();
        $project = $projectVisibility->assertCanAccessCompanyProject((int) $user->id, $companyId, $projectId);

        $transfer = $operationVisibility->assertCanViewTransfer($project, (int) $user->id, $transferId);
        $actor = $this->projectParticipantForUser($request, $project, $companyId);

        $updated = $lifecycle->submitForApprovalByEmployee($project, $transfer, $actor, $user);

        return ApiResponse::ok([
            'transfer' => (new TransferOperationResource($updated))->resolve(),
        ]);
    }
}
