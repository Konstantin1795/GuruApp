<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Requests\UpdateProjectExpenseItemRequest;
use App\Modules\Projects\Services\ProjectExpenseItemAccessService;
use App\Modules\Projects\Services\ProjectExpenseItemService;
use App\Support\Http\ApiResponse;

final class PatchProjectExpenseItemController
{
    public function __invoke(
        UpdateProjectExpenseItemRequest $request,
        ProjectExpenseItemAccessService $access,
        ProjectExpenseItemService $items,
        int $companyId,
        int $projectId,
        int $expenseItemId,
    ) {
        $project = $access->assertCanManage($request->user(), $companyId, $projectId);

        $item = $items->findActiveForProject((int) $project->id, $expenseItemId);
        if ($item === null) {
            abort(404);
        }

        $markupEnabled = $request->boolean('markup_enabled');
        $profitShares = $request->input('profit_shares', []);
        $markupShares = $markupEnabled ? $request->input('markup_shares', []) : [];

        $updated = $items->updateItem(
            $request->user(),
            $companyId,
            $item,
            trim((string) $request->input('name')),
            is_array($profitShares) ? $profitShares : [],
            $markupEnabled,
            $request->input('markup_percent'),
            is_array($markupShares) ? $markupShares : [],
        );

        return ApiResponse::ok([
            'expense_item' => $items->toDetailPayload($updated),
        ]);
    }
}
