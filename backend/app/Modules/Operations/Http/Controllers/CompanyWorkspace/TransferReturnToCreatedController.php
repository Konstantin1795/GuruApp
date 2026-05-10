<?php

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesProjectParticipant;
use App\Modules\Operations\Http\Requests\TransferCommentRequest;
use App\Modules\Operations\Http\Resources\TransferOperationResource;
use App\Modules\Operations\Services\OperationVisibilityService;
use App\Modules\Operations\Services\TransferLifecycleService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;

final class TransferReturnToCreatedController
{
    use ResolvesProjectParticipant;

    public function __invoke(
        TransferCommentRequest $request,
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

        $comment = (string) $request->validated('comment');
        $updated = $lifecycle->returnToCreatedFromWaitingByEmployee($project, $transfer, $actor, $user, $comment);

        return ApiResponse::ok([
            'transfer' => (new TransferOperationResource($updated))->resolve(),
        ]);
    }
}
