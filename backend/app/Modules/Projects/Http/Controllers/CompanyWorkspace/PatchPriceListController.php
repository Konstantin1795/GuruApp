<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Requests\PatchPriceListRequest;
use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\PriceListService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class PatchPriceListController
{
    public function __invoke(
        Request $request,
        PatchPriceListRequest $body,
        PriceListAccessService $access,
        PriceListService $lists,
        int $companyId,
        int $priceListId,
    ) {
        $list = $lists->findVisibleInCompany($companyId, $priceListId);
        if (! $list) {
            abort(404, 'Not found.');
        }

        $access->assertCanEditPriceList($request->user(), $companyId, $list);

        $list = $lists->update($request->user(), $list, $body->validated()['name']);

        return ApiResponse::ok([
            'price_list' => $lists->detailPayload($list, $access->canEditPriceList($request->user(), $companyId, $list)),
        ]);
    }
}
