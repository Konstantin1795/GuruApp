<?php

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Resources\IncomeOperationResource;
use App\Modules\Operations\Services\IncomeAvailableActionsService;
use App\Modules\Operations\Services\IncomeVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ShowIncomeController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        IncomeVisibilityService $incomeVisibility,
        IncomeAvailableActionsService $availableActions,
        int $companyId,
        int $projectId,
        int $incomeId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessCompanyProject($userId, $companyId, $projectId);

        $income = $incomeVisibility
            ->assertCanViewIncome($project, $userId, $incomeId)
            ->load([
                'initiator.counterparty.user',
                'projectHead.counterparty.user',
                'customer.counterparty.user',
                'project',
                'operation.statusHistory',
            ]);

        $participant = $incomeVisibility->participantForUser($project, $userId);

        return ApiResponse::ok([
            'income' => (new IncomeOperationResource($income))->resolve(),
            'available_actions' => $participant !== null
                ? $availableActions->forParticipant($participant, $income)
                : [],
        ]);
    }
}
