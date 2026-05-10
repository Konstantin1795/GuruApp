<?php

namespace App\Modules\Companies\Http\Controllers\PersonalWorkspace;

use App\Modules\Companies\Http\Resources\PersonalCompanyResource;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Workspaces\Support\PersonalWorkspaceRoleFilter;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\PaginatedResourceResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

final class ListCompaniesController
{
    public function __invoke(Request $request)
    {
        $p = Pagination::fromRequest($request);
        $userId = (int) $request->user()->id;

        $roleFilter = PersonalWorkspaceRoleFilter::fromQuery($request->query('workspace_role'));

        $rolePlaceholders = implode(',', array_fill(0, count($roleFilter), '?'));
        $roleBindings = $roleFilter;

        $baseQuery = Counterparty::query()
            ->select([
                'companies.id as company_id',
                'companies.name as company_name',
                'companies.is_active as is_active',
                'counterparties.company_role_code as company_role_code',
            ])
            ->join('companies', 'companies.id', '=', 'counterparties.company_id')
            ->join('project_participants', 'project_participants.counterparty_id', '=', 'counterparties.id')
            ->where('counterparties.user_id', $userId)
            ->where('counterparties.is_active', true)
            ->where('project_participants.is_active', true)
            ->whereIn('counterparties.company_role_code', $roleFilter)
            ->selectRaw(
                '(select count(distinct pp.project_id) from project_participants pp '.
                'inner join counterparties c2 on c2.id = pp.counterparty_id '.
                'inner join projects pr on pr.id = pp.project_id '.
                'where c2.user_id = ? and pp.is_active = true and c2.is_active = true '.
                'and c2.company_role_code in ('.$rolePlaceholders.') '.
                'and pr.company_id = companies.id) as projects_count',
                array_merge([$userId], $roleBindings),
            )
            ->orderByDesc('companies.id');

        // Distinct by company_id (a user should normally have max one counterparty per company)
        $query = $baseQuery->distinct('companies.id');

        // Eloquent paginator with a distinct select can be DB-driver-sensitive;
        // use the query builder paginator for deterministic behavior.
        $paginator = DB::query()
            ->fromSub($query, 't')
            ->paginate(
                perPage: $p['per_page'],
                page: $p['page'],
            );

        $items = collect($paginator->items());
        $collection = PersonalCompanyResource::collection($items);

        return ApiResponse::ok(PaginatedResourceResponse::fromPaginator($collection, $paginator));
    }
}

