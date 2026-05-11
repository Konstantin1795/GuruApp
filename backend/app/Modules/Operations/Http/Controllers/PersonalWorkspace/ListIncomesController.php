<?php

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Http\Resources\IncomeOperationResource;
use App\Modules\Operations\Services\IncomeVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\PaginatedResourceResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListIncomesController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        IncomeVisibilityService $incomeVisibility,
        int $projectId,
    ) {
        $p = Pagination::fromRequest($request);
        $userId = (int) $request->user()->id;

        $project = $projectVisibility->assertCanAccessPersonalWorkspaceProject($userId, $projectId);

        $query = $incomeVisibility
            ->incomeQueryForUser($project, $userId)
            ->with([
                'initiator.counterparty.user',
                'projectHead.counterparty.user',
                'customer.counterparty.user',
                'project',
            ]);

        $paginator = $query
            ->orderByDesc('income_operations.id')
            ->paginate(perPage: $p['per_page'], page: $p['page']);

        $collection = IncomeOperationResource::collection($paginator->items());

        return ApiResponse::ok(PaginatedResourceResponse::fromPaginator($collection, $paginator));
    }
}
