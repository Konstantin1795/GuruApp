<?php

namespace App\Modules\Companies\Http\Controllers\PersonalWorkspace;

use App\Modules\Companies\Http\Resources\PersonalCompanyResource;
use App\Modules\Companies\Models\Counterparty;
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

        $baseQuery = Counterparty::query()
            ->select([
                'companies.id as company_id',
                'companies.name as company_name',
                'companies.is_active as is_active',
                'counterparties.company_role_code as company_role_code',
            ])
            ->join('companies', 'companies.id', '=', 'counterparties.company_id')
            ->where('counterparties.user_id', $userId)
            ->where('counterparties.is_active', true)
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

