<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\ProjectExpenseItemAccessService;
use App\Modules\Projects\Services\ProjectExpenseItemRecipientService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ListProjectExpenseItemRecipientsController
{
    public function __invoke(
        Request $request,
        ProjectExpenseItemAccessService $access,
        ProjectExpenseItemRecipientService $recipients,
        int $companyId,
        int $projectId,
    ) {
        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
        ]);

        $access->assertCanManage($request->user(), $companyId, $projectId);

        $list = $recipients->listCompanyCounterparties(
            $companyId,
            $validated['search'] ?? null,
        );

        return ApiResponse::ok([
            'source' => 'company_counterparties',
            'recipients' => $list->all(),
        ]);
    }
}
