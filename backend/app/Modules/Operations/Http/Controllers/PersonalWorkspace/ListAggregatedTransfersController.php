<?php

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Http\Resources\TransferOperationResource;
use App\Modules\Operations\Services\OperationVisibilityService;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\PaginatedResourceResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListAggregatedTransfersController
{
    public function __invoke(
        Request $request,
        OperationVisibilityService $operationVisibility,
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

        $query = $operationVisibility
            ->transferQueryForUserAcrossProjects($projects, $userId)
            ->with(['sender.counterparty.user', 'receiver.counterparty.user', 'project']);

        $paginator = $query
            ->orderByDesc('transfer_operations.id')
            ->paginate(
                perPage: $p['per_page'],
                page: $p['page'],
            );

        $collection = TransferOperationResource::collection($paginator->items());

        return ApiResponse::ok(PaginatedResourceResponse::fromPaginator($collection, $paginator));
    }
}
