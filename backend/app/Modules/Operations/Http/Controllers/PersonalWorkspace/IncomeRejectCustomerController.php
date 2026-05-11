<?php

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesPersonalWorkspaceProjectParticipant;
use App\Modules\Operations\Http\Requests\TransferCommentRequest;
use App\Modules\Operations\Http\Resources\IncomeOperationResource;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Services\IncomeLifecycleService;
use App\Modules\Operations\Services\IncomeVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;

final class IncomeRejectCustomerController
{
    use ResolvesPersonalWorkspaceProjectParticipant;

    public function __invoke(
        TransferCommentRequest $request,
        IncomeLifecycleService $lifecycle,
        ProjectVisibilityService $projectVisibility,
        IncomeVisibilityService $incomeVisibility,
        int $projectId,
        int $incomeId,
    ) {
        $user = $request->user();
        $project = $projectVisibility->assertCanAccessPersonalWorkspaceProject((int) $user->id, $projectId);

        /** @var IncomeOperation $income */
        $income = $incomeVisibility->assertCanViewIncome($project, (int) $user->id, $incomeId);

        $actor = $this->projectParticipantForPersonalWorkspace($request, $project);

        $updated = $lifecycle->rejectByCustomer(
            $project,
            $income,
            $actor,
            $user,
            (string) $request->validated('comment'),
        );

        return ApiResponse::ok([
            'income' => (new IncomeOperationResource($updated))->resolve(),
        ]);
    }
}
