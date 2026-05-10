<?php

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Enums\TransferTargetType;
use App\Modules\Operations\Http\Concerns\ResolvesPersonalWorkspaceProjectParticipant;
use App\Modules\Operations\Http\Requests\CreateTransferRequest;
use App\Modules\Operations\Http\Resources\TransferOperationResource;
use App\Modules\Operations\Services\PersonalWorkspaceTransferGuard;
use App\Modules\Operations\Services\TransferService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;

final class CreateTransferController
{
    use ResolvesPersonalWorkspaceProjectParticipant;

    public function __invoke(
        CreateTransferRequest $request,
        TransferService $service,
        ProjectVisibilityService $visibility,
        PersonalWorkspaceTransferGuard $guard,
        int $projectId,
    ) {
        $project = $visibility->assertCanAccessPersonalWorkspaceProject((int) $request->user()->id, $projectId);
        $companyId = (int) $project->company_id;

        $initiator = $this->projectParticipantForPersonalWorkspace($request, $project);
        $guard->assertCanInitiateTransfer($initiator);

        $payload = $request->validated();
        $targetType = TransferTargetType::from((string) $payload['transfer_target_type']);

        $transfer = $service->create(
            project: $project,
            companyId: $companyId,
            initiator: $initiator,
            targetType: $targetType,
            amount: (string) $payload['amount'],
            comment: isset($payload['comment']) ? (string) $payload['comment'] : null,
            receiverProjectParticipantId: isset($payload['receiver_project_participant_id'])
                ? (int) $payload['receiver_project_participant_id']
                : null,
            receiverCounterpartyId: isset($payload['receiver_counterparty_id'])
                ? (int) $payload['receiver_counterparty_id']
                : null,
        );

        return ApiResponse::ok([
            'transfer' => (new TransferOperationResource($transfer))->toArray($request),
        ], status: 201);
    }
}
