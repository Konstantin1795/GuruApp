<?php

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesPersonalWorkspaceProjectParticipant;
use App\Modules\Operations\Http\Resources\TransferOperationResource;
use App\Modules\Operations\Services\OperationVisibilityService;
use App\Modules\Operations\Services\PersonalWorkspaceTransferGuard;
use App\Modules\Operations\Services\TransferLifecycleService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class TransferSubmitForApprovalController
{
    use ResolvesPersonalWorkspaceProjectParticipant;

    public function __invoke(
        Request $request,
        TransferLifecycleService $lifecycle,
        ProjectVisibilityService $projectVisibility,
        OperationVisibilityService $operationVisibility,
        PersonalWorkspaceTransferGuard $guard,
        int $projectId,
        int $transferId,
    ) {
        $user = $request->user();
        $project = $projectVisibility->assertCanAccessPersonalWorkspaceProject((int) $user->id, $projectId);

        $transfer = $operationVisibility->assertCanViewTransfer($project, (int) $user->id, $transferId);
        $actor = $this->projectParticipantForPersonalWorkspace($request, $project);
        $guard->assertCanInitiateTransfer($actor);

        $updated = $lifecycle->submitForApprovalByEmployee($project, $transfer, $actor, $user);

        return ApiResponse::ok([
            'transfer' => (new TransferOperationResource($updated))->resolve(),
        ]);
    }
}
