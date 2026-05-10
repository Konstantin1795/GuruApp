<?php

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesPersonalWorkspaceProjectParticipant;
use App\Modules\Operations\Http\Requests\TransferCommentRequest;
use App\Modules\Operations\Http\Resources\TransferOperationResource;
use App\Modules\Operations\Services\OperationVisibilityService;
use App\Modules\Operations\Services\PersonalWorkspaceTransferGuard;
use App\Modules\Operations\Services\TransferLifecycleService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;

final class TransferReturnToCreatedController
{
    use ResolvesPersonalWorkspaceProjectParticipant;

    public function __invoke(
        TransferCommentRequest $request,
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

        $comment = (string) $request->validated('comment');
        $updated = $lifecycle->returnToCreatedFromWaitingByEmployee($project, $transfer, $actor, $user, $comment);

        return ApiResponse::ok([
            'transfer' => (new TransferOperationResource($updated))->resolve(),
        ]);
    }
}
