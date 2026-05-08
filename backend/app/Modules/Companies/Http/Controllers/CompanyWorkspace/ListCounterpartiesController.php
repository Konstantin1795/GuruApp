<?php

namespace App\Modules\Companies\Http\Controllers\CompanyWorkspace;

use App\Modules\Companies\Http\Resources\CounterpartyResource;
use App\Modules\Companies\Models\Counterparty;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\PaginatedResourceResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListCounterpartiesController
{
    public function __invoke(Request $request, int $companyId)
    {
        $p = Pagination::fromRequest($request);

        $query = Counterparty::query()
            ->where('company_id', $companyId)
            ->orderByDesc('id');

        $paginator = $query->paginate(
            perPage: $p['per_page'],
            page: $p['page'],
        );

        $collection = CounterpartyResource::collection($paginator->items());

        return ApiResponse::ok(PaginatedResourceResponse::fromPaginator($collection, $paginator));
    }
}

