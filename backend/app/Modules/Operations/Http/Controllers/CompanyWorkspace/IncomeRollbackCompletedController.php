<?php

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesProjectParticipant;
use App\Modules\Operations\Http\Requests\TransferCommentRequest;
use App\Modules\Operations\Http\Resources\IncomeOperationResource;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Services\IncomeLifecycleService;
use App\Modules\Operations\Services\IncomeVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;

final class IncomeRollbackCompletedController
{
    use ResolvesProjectParticipant;

    public function __invoke(
        TransferCommentRequest $request,
        IncomeLifecycleService $lifecycle,
        ProjectVisibilityService $projectVisibility,
        IncomeVisibilityService $incomeVisibility,
        int $companyId,
        int $projectId,
        int $incomeId,
    ) {
        $user = $request->user();
        $project = $projectVisibility->assertCanAccessCompanyProject((int) $user->id, $companyId, $projectId);

        /** @var IncomeOperation $income */
        $income = $incomeVisibility->assertCanViewIncome($project, (int) $user->id, $incomeId);

        $actor = $this->projectParticipantForUser($request, $project, $companyId);

        $updated = $lifecycle->rollbackCompleted(
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
