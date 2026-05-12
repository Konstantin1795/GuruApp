<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\PriceListDeletionService;
use App\Modules\Projects\Services\PriceListGroupService;
use App\Modules\Projects\Services\PriceListService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class DeletePriceListGroupController
{
    public function __invoke(
        Request $request,
        PriceListAccessService $access,
        PriceListService $lists,
        PriceListGroupService $groups,
        PriceListDeletionService $deletion,
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

        $groups->delete($group, $deletion);

        return ApiResponse::ok([
            'deleted' => true,
        ]);
    }
}
