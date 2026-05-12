<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Requests\StorePriceListGroupRequest;
use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\PriceListGroupService;
use App\Modules\Projects\Services\PriceListService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class CreatePriceListGroupController
{
    public function __invoke(
        Request $request,
        StorePriceListGroupRequest $body,
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

        $access->assertCanEditPriceList($request->user(), $companyId, $list);

        $group = $groups->create($request->user(), $list, $body->validated()['name']);

        return ApiResponse::ok([
            'group' => $groups->toListPayload($group),
        ], [], 201);
    }
}
