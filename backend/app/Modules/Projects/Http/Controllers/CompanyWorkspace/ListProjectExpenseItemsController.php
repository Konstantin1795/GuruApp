<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\ProjectExpenseItemAccessService;
use App\Modules\Projects\Services\ProjectExpenseItemService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ListProjectExpenseItemsController
{
    public function __invoke(
        Request $request,
        ProjectExpenseItemAccessService $access,
        ProjectExpenseItemService $items,
        int $companyId,
        int $projectId,
    ) {
        $project = $access->assertCanView($request->user(), $companyId, $projectId);

        return ApiResponse::ok([
            'expense_items' => $items->listActiveForProject((int) $project->id),
        ]);
    }
}
