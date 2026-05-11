<?php

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Http\Resources\IncomeOperationResource;
use App\Modules\Operations\Services\IncomeVisibilityService;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\PaginatedResourceResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListAggregatedIncomesController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        IncomeVisibilityService $incomeVisibility,
    ) {
        $p = Pagination::fromRequest($request);
        $userId = (int) $request->user()->id;

        $projectIds = ProjectParticipant::query()
            ->where('is_active', true)
            ->whereHas('counterparty', function ($q) use ($userId): void {
                $q->where('user_id', $userId)->where('is_active', true);
            })
            ->distinct()
            ->pluck('project_id');

        $projects = Project::query()->whereIn('id', $projectIds)->get();

        $query = $incomeVisibility
            ->incomeQueryForUserAcrossProjects($projects, $userId)
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
