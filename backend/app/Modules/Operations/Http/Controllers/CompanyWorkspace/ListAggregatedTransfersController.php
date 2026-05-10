<?php

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Resources\TransferOperationResource;
use App\Modules\Operations\Services\OperationVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\PaginatedResourceResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListAggregatedTransfersController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        OperationVisibilityService $operationVisibility,
        int $companyId,
    ) {
        $p = Pagination::fromRequest($request);
        $userId = (int) $request->user()->id;

        $projects = $projectVisibility
            ->queryForCompanyWorkspace($userId, $companyId)
            ->get();

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
