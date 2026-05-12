<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\PriceListDeletionService;
use App\Modules\Projects\Services\PriceListService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class DeletePriceListController
{
    public function __invoke(
        Request $request,
        PriceListAccessService $access,
        PriceListService $lists,
        PriceListDeletionService $deletion,
        int $companyId,
        int $priceListId,
    ) {
        $list = \App\Modules\Projects\Models\PriceList::query()
            ->where('company_id', $companyId)
            ->whereKey($priceListId)
            ->firstOrFail();

        $access->assertCanDeletePriceList($request->user(), $companyId, $list);

        $projectsCount = $deletion->countProjectsUsingPriceList((int) $list->id);

        $result = $lists->delete($list);

        return ApiResponse::ok([
            'deleted_mode' => $result['deleted_mode'],
            'detached_projects_count' => $result['detached_projects_count'],
            'projects_count_before_delete' => $projectsCount,
        ]);
    }
}
