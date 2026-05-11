<?php

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesPersonalWorkspaceProjectParticipant;
use App\Modules\Operations\Http\Resources\IncomeOperationResource;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Services\IncomeLifecycleService;
use App\Modules\Operations\Services\IncomeVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class IncomeReturnToCustomerApprovalController
{
    use ResolvesPersonalWorkspaceProjectParticipant;

    public function __invoke(
        Request $request,
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

        $updated = $lifecycle->returnToCustomerApprovalFromWaiting($project, $income, $actor, $user);

        return ApiResponse::ok([
            'income' => (new IncomeOperationResource($updated))->resolve(),
        ]);
    }
}
