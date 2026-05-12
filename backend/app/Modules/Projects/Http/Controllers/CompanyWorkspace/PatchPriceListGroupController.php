<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Requests\PatchPriceListGroupRequest;
use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\PriceListGroupService;
use App\Modules\Projects\Services\PriceListService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class PatchPriceListGroupController
{
    public function __invoke(
        Request $request,
        PatchPriceListGroupRequest $body,
        PriceListAccessService $access,
        PriceListService $lists,
        PriceListGroupService $groups,
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

        $group = $groups->update($request->user(), $group, $body->validated()['name']);

        return ApiResponse::ok([
            'group' => $groups->toListPayload($group),
        ]);
    }
}
