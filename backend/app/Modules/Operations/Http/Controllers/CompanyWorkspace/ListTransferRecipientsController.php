<?php

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Enums\TransferTargetType;
use App\Modules\Operations\Http\Concerns\ResolvesProjectParticipant;
use App\Modules\Operations\Services\TransferRecipientListService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

final class ListTransferRecipientsController
{
    use ResolvesProjectParticipant;

    public function __invoke(
        Request $request,
        TransferRecipientListService $recipients,
        ProjectVisibilityService $visibility,
        int $companyId,
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

        $project = $visibility->assertCanAccessCompanyProject(
            (int) $request->user()->id,
            $companyId,
            $projectId,
        );

        if ((int) $project->company_id !== $companyId) {
            throw ValidationException::withMessages(['project' => ['Несоответствие компании и проекта.']]);
        }

        $initiator = $this->projectParticipantForUser($request, $project, $companyId);

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
