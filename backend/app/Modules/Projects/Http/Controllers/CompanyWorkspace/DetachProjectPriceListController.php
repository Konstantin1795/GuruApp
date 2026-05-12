<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Models\PriceList;
use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\ProjectPriceListService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class DetachProjectPriceListController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $visibility,
        PriceListAccessService $access,
        ProjectPriceListService $projectLists,
        int $companyId,
        int $projectId,
        int $priceListId,
    ) {
        $project = $visibility->assertCanAccessCompanyProject(
            (int) $request->user()->id,
            $companyId,
            $projectId,
        );

        $list = PriceList::query()
            ->where('company_id', $companyId)
            ->whereKey($priceListId)
            ->firstOrFail();

        $access->assertCanDetachPriceListFromProject($request->user(), $companyId, $project, $list);

        $projectLists->detach($project, $priceListId);

        return ApiResponse::ok([
            'detached' => true,
        ]);
    }
}
