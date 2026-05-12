<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\ProjectExpenseItemAccessService;
use App\Modules\Projects\Services\ProjectPriceListService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ListProjectPriceListsController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $visibility,
        ProjectExpenseItemAccessService $expenseAccess,
        ProjectPriceListService $projectLists,
        int $companyId,
        int $projectId,
    ) {
        $project = $visibility->assertCanAccessCompanyProject(
            (int) $request->user()->id,
            $companyId,
            $projectId,
        );

        if (! $expenseAccess->canView($request->user(), $companyId, $project)) {
            abort(403, 'Forbidden.');
        }

        return ApiResponse::ok([
            'project_price_lists' => $projectLists->listAttached($project),
        ]);
    }
}
