<?php

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Enums\TransferTargetType;
use App\Modules\Operations\Http\Concerns\ResolvesPersonalWorkspaceProjectParticipant;
use App\Modules\Operations\Services\PersonalWorkspaceTransferGuard;
use App\Modules\Operations\Services\TransferRecipientListService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

final class ListTransferRecipientsController
{
    use ResolvesPersonalWorkspaceProjectParticipant;

    public function __invoke(
        Request $request,
        TransferRecipientListService $recipients,
        ProjectVisibilityService $visibility,
        PersonalWorkspaceTransferGuard $guard,
        int $projectId,
    ) {
        $request->validate([
            'transfer_target_type' => [
                'required',
                'string',
                Rule::in(array_map(static fn (TransferTargetType $t) => $t->value, TransferTargetType::cases())),
            ],
        ]);

        $type = TransferTargetType::from((string) $request->query('transfer_target_type'));

        $project = $visibility->assertCanAccessPersonalWorkspaceProject((int) $request->user()->id, $projectId);
        $companyId = (int) $project->company_id;

        $initiator = $this->projectParticipantForPersonalWorkspace($request, $project);
        $guard->assertCanInitiateTransfer($initiator);

        $items = $recipients->list(
            $project,
            $companyId,
            $type,
            $type === TransferTargetType::ACCOUNTABLE_BALANCE ? $initiator->id : null,
        );

        return ApiResponse::ok([
            'transfer_target_type' => $type->value,
            'recipients' => $items->values()->all(),
        ]);
    }
}
