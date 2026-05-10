<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Resources\ProjectParticipantResource;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\PaginatedResourceResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListProjectParticipantsController
{
    public function __invoke(Request $request, ProjectVisibilityService $visibility, int $companyId, int $projectId)
    {
        $p = Pagination::fromRequest($request);

        $project = $visibility->assertCanAccessCompanyProject(
            (int) $request->user()->id,
            $companyId,
            $projectId,
        );

        $query = ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->with(['counterparty.user'])
            ->orderByDesc('id');

        $paginator = $query->paginate(
            perPage: $p['per_page'],
            page: $p['page'],
        );

        $collection = ProjectParticipantResource::collection($paginator->items());

        return ApiResponse::ok(PaginatedResourceResponse::fromPaginator($collection, $paginator));
    }
}
