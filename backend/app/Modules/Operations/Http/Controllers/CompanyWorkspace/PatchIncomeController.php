<?php

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesProjectParticipant;
use App\Modules\Operations\Http\Requests\UpdateIncomeRequest;
use App\Modules\Operations\Http\Resources\IncomeOperationResource;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Services\IncomeLifecycleService;
use App\Modules\Operations\Services\IncomeVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;

final class PatchIncomeController
{
    use ResolvesProjectParticipant;

    public function __invoke(
        UpdateIncomeRequest $request,
        IncomeLifecycleService $lifecycle,
        ProjectVisibilityService $projectVisibility,
        IncomeVisibilityService $incomeVisibility,
        int $companyId,
        int $projectId,
        int $incomeId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessCompanyProject($userId, $companyId, $projectId);

        /** @var IncomeOperation $income */
        $income = $incomeVisibility->assertCanViewIncome($project, $userId, $incomeId);

        $actor = $this->projectParticipantForUser($request, $project, $companyId);
        if ((int) $income->initiator_project_participant_id !== (int) $actor->id) {
            abort(403, 'Редактирование доступно только инициатору.');
        }

        $payload = $request->validated();

        $updated = $lifecycle->updateDraftInCreated(
            $income,
            (string) $payload['amount'],
            isset($payload['comment']) ? (string) $payload['comment'] : null,
        );

        return ApiResponse::ok([
            'income' => (new IncomeOperationResource($updated))->resolve(),
        ]);
    }
}
