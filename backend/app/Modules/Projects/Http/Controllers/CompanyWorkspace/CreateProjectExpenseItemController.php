<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Requests\StoreProjectExpenseItemRequest;
use App\Modules\Projects\Services\ProjectExpenseItemAccessService;
use App\Modules\Projects\Services\ProjectExpenseItemService;
use App\Support\Http\ApiResponse;

final class CreateProjectExpenseItemController
{
    public function __invoke(
        StoreProjectExpenseItemRequest $request,
        ProjectExpenseItemAccessService $access,
        ProjectExpenseItemService $items,
        int $companyId,
        int $projectId,
    ) {
        $project = $access->assertCanManage($request->user(), $companyId, $projectId);

        $markupEnabled = $request->boolean('markup_enabled');
        $profitShares = $request->input('profit_shares', []);
        $markupShares = $markupEnabled ? $request->input('markup_shares', []) : [];

        $item = $items->create(
            $request->user(),
            $companyId,
            (int) $project->id,
            trim((string) $request->input('name')),
            is_array($profitShares) ? $profitShares : [],
            $markupEnabled,
            $request->input('markup_percent'),
            is_array($markupShares) ? $markupShares : [],
        );

        return ApiResponse::ok([
            'expense_item' => $items->toDetailPayload($item),
        ], [], 201);
    }
}
