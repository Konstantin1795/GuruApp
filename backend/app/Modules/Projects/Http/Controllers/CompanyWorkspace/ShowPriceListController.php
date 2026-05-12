<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\PriceListService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ShowPriceListController
{
    public function __invoke(
        Request $request,
        PriceListAccessService $access,
        PriceListService $lists,
        int $companyId,
        int $priceListId,
    ) {
        $list = $lists->findVisibleInCompany($companyId, $priceListId);
        if (! $list) {
            abort(404, 'Not found.');
        }

        $access->assertCanViewPriceList($request->user(), $companyId, $list);

        return ApiResponse::ok([
            'price_list' => $lists->detailPayload(
                $list,
                $access->canEditPriceList($request->user(), $companyId, $list),
            ),
        ]);
    }
}
