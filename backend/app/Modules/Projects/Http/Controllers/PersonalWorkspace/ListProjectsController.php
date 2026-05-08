<?php

namespace App\Modules\Projects\Http\Controllers\PersonalWorkspace;

use App\Modules\Projects\Http\Resources\PersonalProjectResource;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\PaginatedResourceResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

final class ListProjectsController
{
    public function __invoke(Request $request)
    {
        $p = Pagination::fromRequest($request);
        $userId = (int) $request->user()->id;

        $query = DB::table('project_participants')
            ->select([
                'projects.id as project_id',
                'projects.name as project_name',
                'projects.progress_percent as progress_percent',
                'projects.is_active as is_active',
                'companies.id as company_id',
                'companies.name as company_name',
            ])
            ->join('counterparties', 'counterparties.id', '=', 'project_participants.counterparty_id')
            ->join('projects', 'projects.id', '=', 'project_participants.project_id')
            ->join('companies', 'companies.id', '=', 'projects.company_id')
            ->where('counterparties.user_id', $userId)
            ->where('counterparties.is_active', true)
            ->where('project_participants.is_active', true)
            ->orderByDesc('projects.id')
            ->distinct('projects.id');

        $paginator = $query->paginate(
            perPage: $p['per_page'],
            page: $p['page'],
        );

        $items = collect($paginator->items());
        $collection = PersonalProjectResource::collection($items);

        return ApiResponse::ok(PaginatedResourceResponse::fromPaginator($collection, $paginator));
    }
}

