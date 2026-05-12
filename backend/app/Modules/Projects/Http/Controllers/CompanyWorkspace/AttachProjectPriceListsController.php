<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Requests\AttachProjectPriceListsRequest;
use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\ProjectPriceListService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class AttachProjectPriceListsController
{
    public function __invoke(
        Request $request,
        AttachProjectPriceListsRequest $body,
        ProjectVisibilityService $visibility,
        PriceListAccessService $access,
        ProjectPriceListService $projectLists,
        int $companyId,
        int $projectId,
    ) {
        $project = $visibility->assertCanAccessCompanyProject(
            (int) $request->user()->id,
            $companyId,
            $projectId,
        );

        $attached = $projectLists->attach(
            $request->user(),
            $companyId,
            $project,
            $body->validated()['price_list_ids'],
            $access,
        );

        return ApiResponse::ok([
            'attached_price_list_ids' => $attached,
        ]);
    }
}
