<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\PriceListService;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListPriceListsController
{
    public function __invoke(
        Request $request,
        PriceListAccessService $access,
        PriceListService $lists,
        int $companyId,
    ) {
        $p = Pagination::fromRequest($request);
        $search = $request->query('search');

        $paginator = $lists->paginateForCompany(
            $access,
            $request->user(),
            $companyId,
            is_string($search) ? $search : null,
            $p['page'],
            $p['per_page'],
        );

        $items = collect($paginator->items())->map(fn ($row) => $lists->listItemPayload($row))->values()->all();

        return ApiResponse::ok([
            'items' => $items,
            'pagination' => [
                'page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
            ],
        ]);
    }
}
