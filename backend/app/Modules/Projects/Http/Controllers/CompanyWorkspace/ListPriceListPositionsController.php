<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\PriceListGroupService;
use App\Modules\Projects\Services\PriceListPositionService;
use App\Modules\Projects\Services\PriceListService;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListPriceListPositionsController
{
    public function __invoke(
        Request $request,
        PriceListAccessService $access,
        PriceListService $lists,
        PriceListGroupService $groups,
        PriceListPositionService $positions,
        int $companyId,
        int $priceListId,
        int $groupId,
    ) {
        $list = $lists->findVisibleInCompany($companyId, $priceListId);
        if (! $list) {
            abort(404, 'Not found.');
        }

        $access->assertCanViewPriceList($request->user(), $companyId, $list);

        $group = $groups->findVisible($list, $groupId);
        if (! $group) {
            abort(404, 'Not found.');
        }

        $p = Pagination::fromRequest($request);
        $search = $request->query('search');

        $paginator = $positions->paginateForGroup(
            $group,
            is_string($search) ? $search : null,
            $p['page'],
            $p['per_page'],
        );

        $items = collect($paginator->items())
            ->map(fn ($row) => $positions->toPayload($row))
            ->values()
            ->all();

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
