<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Resources\ProjectResource;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\PaginatedResourceResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListProjectsController
{
    public function __invoke(Request $request, ProjectVisibilityService $visibility, int $companyId)
    {
        $p = Pagination::fromRequest($request);

        $query = $visibility
            ->queryForCompanyWorkspace((int) $request->user()->id, $companyId)
            ->orderByDesc('id');

        $paginator = $query->paginate(
            perPage: $p['per_page'],
            page: $p['page'],
        );

        $collection = ProjectResource::collection($paginator->items());

        return ApiResponse::ok(PaginatedResourceResponse::fromPaginator($collection, $paginator));
    }
}

