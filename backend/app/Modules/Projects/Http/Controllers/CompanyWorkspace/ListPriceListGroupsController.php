<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\PriceListGroupService;
use App\Modules\Projects\Services\PriceListService;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListPriceListGroupsController
{
    public function __invoke(
        Request $request,
        PriceListAccessService $access,
        PriceListService $lists,
        PriceListGroupService $groups,
        int $companyId,
        int $priceListId,
    ) {
        $list = $lists->findVisibleInCompany($companyId, $priceListId);
        if (! $list) {
            abort(404, 'Not found.');
        }

        $access->assertCanViewPriceList($request->user(), $companyId, $list);

        $p = Pagination::fromRequest($request);
        $search = $request->query('search');

        $paginator = $groups->paginateForGroup(
            $list,
            is_string($search) ? $search : null,
            $p['page'],
            $p['per_page'],
        );

        $items = collect($paginator->items())->map(fn ($g) => $groups->toListPayload($g))->values()->all();

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
