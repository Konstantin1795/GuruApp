<?php

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Http\Resources\TransferOperationResource;
use App\Modules\Operations\Services\OperationVisibilityService;
use App\Modules\Operations\Services\TransferAvailableActionsService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ShowTransferController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        OperationVisibilityService $operationVisibility,
        TransferAvailableActionsService $availableActions,
        int $projectId,
        int $transferId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessPersonalWorkspaceProject($userId, $projectId);

        $transfer = $operationVisibility
            ->assertCanViewTransfer($project, $userId, $transferId)
            ->load([
                'initiator',
                'sender.counterparty.user',
                'receiver.counterparty.user',
                'operation.statusHistory',
                'reportTransferLink.reportOperation',
            ]);

        $participant = $operationVisibility->participantForUser($project, $userId);

        return ApiResponse::ok([
            'transfer' => (new TransferOperationResource($transfer))->resolve(),
            'available_actions' => $participant !== null
                ? $availableActions->forParticipant($participant, $transfer)
                : [],
        ]);
    }
}
