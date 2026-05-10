<?php

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Resources\TransferOperationResource;
use App\Modules\Operations\Services\OperationVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\PaginatedResourceResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListTransfersController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        OperationVisibilityService $operationVisibility,
        int $companyId,
        int $projectId,
    )
    {
        $p = Pagination::fromRequest($request);
        $userId = (int) $request->user()->id;

        $project = $projectVisibility->assertCanAccessCompanyProject($userId, $companyId, $projectId);

        $query = $operationVisibility
            ->transferQueryForUser($project, $userId)
            ->with(['sender.counterparty.user', 'receiver.counterparty.user'])
            ->orderByDesc('id');

        $paginator = $query->paginate(
            perPage: $p['per_page'],
            page: $p['page'],
        );

        $collection = TransferOperationResource::collection($paginator->items());

        return ApiResponse::ok(PaginatedResourceResponse::fromPaginator($collection, $paginator));
    }
}
