<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Requests\StorePriceListPositionRequest;
use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\PriceListGroupService;
use App\Modules\Projects\Services\PriceListPositionService;
use App\Modules\Projects\Services\PriceListService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class CreatePriceListPositionController
{
    public function __invoke(
        Request $request,
        StorePriceListPositionRequest $body,
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

        $access->assertCanEditPriceList($request->user(), $companyId, $list);

        $group = $groups->findVisible($list, $groupId);
        if (! $group) {
            abort(404, 'Not found.');
        }

        $position = $positions->create($request->user(), $group, $body->validated());

        return ApiResponse::ok([
            'position' => $positions->toPayload($position),
        ], [], 201);
    }
}
