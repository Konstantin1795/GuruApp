<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesProjectParticipant;
use App\Modules\Operations\Http\Resources\IncomeOperationResource;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Services\IncomeLifecycleService;
use App\Modules\Operations\Services\IncomeVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class IncomeResetApprovalController
{
    use ResolvesProjectParticipant;

    public function __invoke(
        Request $request,
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

        $updated = $lifecycle->resetCustomerApprovalToCreated(
            $project,
            $income,
            $actor,
            $request->user(),
        );

        return ApiResponse::ok([
            'income' => (new IncomeOperationResource($updated))->resolve(),
        ]);
    }
}
