<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\ProjectExpenseItemAccessService;
use App\Modules\Projects\Services\ProjectExpenseItemService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ShowProjectExpenseItemController
{
    public function __invoke(
        Request $request,
        ProjectExpenseItemAccessService $access,
        ProjectExpenseItemService $items,
        int $companyId,
        int $projectId,
        int $expenseItemId,
    ) {
        $project = $access->assertCanView($request->user(), $companyId, $projectId);

        $item = $items->findActiveForProject((int) $project->id, $expenseItemId);
        if ($item === null) {
            abort(404);
        }

        return ApiResponse::ok([
            'expense_item' => $items->toDetailPayload($item),
        ]);
    }
}
