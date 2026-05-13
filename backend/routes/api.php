<?php

use Illuminate\Support\Facades\Route;

Route::get('/health', \App\Modules\System\Http\Controllers\HealthController::class);

Route::prefix('auth')->group(function () {
    Route::post('/register', \App\Modules\Auth\Http\Controllers\RegisterController::class);
    Route::post('/token', [\App\Modules\Auth\Http\Controllers\TokenController::class, 'issue']);
    Route::middleware('auth:sanctum')->get('/me', [\App\Modules\Auth\Http\Controllers\TokenController::class, 'me']);
    Route::middleware('auth:sanctum')->post('/logout', \App\Modules\Auth\Http\Controllers\LogoutController::class);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/workspaces', \App\Modules\Workspaces\Http\Controllers\ListWorkspacesController::class);

    // Company Workspace entry action: create a company and become OWNER.
    // This route is NOT scoped by companyId (company does not exist yet).
    Route::post('/company-workspace/companies', \App\Modules\Companies\Http\Controllers\CompanyWorkspace\CreateCompanyController::class);

    Route::prefix('company-workspace/{companyId}')
        ->middleware(\App\Modules\Workspaces\Http\Middleware\EnsureCompanyWorkspaceAccess::class)
        ->group(function () {
            Route::get('/context', \App\Modules\Workspaces\Http\Controllers\CompanyWorkspaceContextController::class);

            Route::get('/operations/transfers/history', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ListAggregatedTransfersController::class);
            Route::get('/operations/transfers/pending-count', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\TransferPendingCountController::class);

            Route::get('/operations/history', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ListAggregatedOperationsHistoryController::class);

            Route::get('/operations/incomes/history', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ListAggregatedIncomesController::class);
            Route::get('/operations/incomes/pending-count', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\IncomePendingCountController::class);
            Route::get('/operations/reports/pending-count', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ReportPendingCountController::class);

            Route::get('/companies/current', \App\Modules\Companies\Http\Controllers\CompanyWorkspace\CurrentCompanyController::class);
            Route::get('/projects', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ListProjectsController::class);
            Route::post('/projects', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\CreateProjectController::class);
            Route::get('/projects/{projectId}/summary', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\GetProjectSummaryController::class);
            Route::get('/projects/{projectId}/internal-metrics', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\GetProjectInternalMetricsController::class);

            Route::get('/units', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ListUnitsController::class);
            Route::get('/price-lists', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ListPriceListsController::class);
            Route::post('/price-lists', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\CreatePriceListController::class);
            Route::get('/price-lists/{priceListId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ShowPriceListController::class)
                ->whereNumber('priceListId');
            Route::patch('/price-lists/{priceListId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\PatchPriceListController::class)
                ->whereNumber('priceListId');
            Route::delete('/price-lists/{priceListId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\DeletePriceListController::class)
                ->whereNumber('priceListId');
            Route::get('/price-lists/{priceListId}/groups', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ListPriceListGroupsController::class)
                ->whereNumber('priceListId');
            Route::post('/price-lists/{priceListId}/groups', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\CreatePriceListGroupController::class)
                ->whereNumber('priceListId');
            Route::patch('/price-lists/{priceListId}/groups/{groupId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\PatchPriceListGroupController::class)
                ->whereNumber('priceListId')->whereNumber('groupId');
            Route::delete('/price-lists/{priceListId}/groups/{groupId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\DeletePriceListGroupController::class)
                ->whereNumber('priceListId')->whereNumber('groupId');
            Route::get('/price-lists/{priceListId}/groups/{groupId}/positions', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ListPriceListPositionsController::class)
                ->whereNumber('priceListId')->whereNumber('groupId');
            Route::post('/price-lists/{priceListId}/groups/{groupId}/positions', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\CreatePriceListPositionController::class)
                ->whereNumber('priceListId')->whereNumber('groupId');
            Route::patch('/price-lists/{priceListId}/groups/{groupId}/positions/{positionId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\PatchPriceListPositionController::class)
                ->whereNumber('priceListId')->whereNumber('groupId')->whereNumber('positionId');
            Route::delete('/price-lists/{priceListId}/groups/{groupId}/positions/{positionId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\DeletePriceListPositionController::class)
                ->whereNumber('priceListId')->whereNumber('groupId')->whereNumber('positionId');

            Route::get('/projects/{projectId}/expense-items/recipients', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ListProjectExpenseItemRecipientsController::class);
            Route::get('/projects/{projectId}/expense-items', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ListProjectExpenseItemsController::class);
            Route::post('/projects/{projectId}/expense-items', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\CreateProjectExpenseItemController::class);
            Route::get('/projects/{projectId}/expense-items/{expenseItemId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ShowProjectExpenseItemController::class)
                ->whereNumber('expenseItemId');
            Route::patch('/projects/{projectId}/expense-items/{expenseItemId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\PatchProjectExpenseItemController::class)
                ->whereNumber('expenseItemId');
            Route::delete('/projects/{projectId}/expense-items/{expenseItemId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\DeleteProjectExpenseItemController::class)
                ->whereNumber('expenseItemId');
            Route::get('/projects/{projectId}/price-lists/available', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ListAvailableProjectPriceListsController::class);
            Route::get('/projects/{projectId}/price-lists', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ListProjectPriceListsController::class);
            Route::post('/projects/{projectId}/price-lists/attach', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\AttachProjectPriceListsController::class);
            Route::delete('/projects/{projectId}/price-lists/{priceListId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\DetachProjectPriceListController::class)
                ->whereNumber('priceListId');
            Route::get('/projects/{projectId}/operations/transfers/recipients', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ListTransferRecipientsController::class);
            Route::get('/projects/{projectId}/operations/transfers', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ListTransfersController::class);
            Route::post('/projects/{projectId}/operations/transfers', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\CreateTransferController::class);
            Route::get('/projects/{projectId}/operations/transfers/{transferId}', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ShowTransferController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/approve-project-head', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\TransferApproveProjectHeadController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/reject-project-head', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\TransferRejectProjectHeadController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/reset-approval', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\TransferResetApprovalController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/submit-for-approval', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\TransferSubmitForApprovalController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/complete-immediate', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\TransferCompleteImmediateController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/return-to-created', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\TransferReturnToCreatedController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/return-to-project-head-approval', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\TransferReturnToProjectHeadApprovalController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/complete-waiting', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\TransferCompleteWaitingController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/rollback-completed', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\TransferRollbackCompletedController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/return-completed-to-project-head-approval', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\TransferReturnCompletedToProjectHeadApprovalController::class);
            Route::get('/projects/{projectId}/participants', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ListProjectParticipantsController::class);
            Route::post('/projects/{projectId}/participants', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\AddProjectParticipantController::class);
            Route::patch('/projects/{projectId}/participants/{participantId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\UpdateProjectParticipantController::class);
            Route::delete('/projects/{projectId}/participants/{participantId}', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\RemoveProjectParticipantController::class);
            Route::get('/projects/{projectId}/participants/{participantId}/wallet', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\GetParticipantWalletController::class);
            Route::get('/counterparties', \App\Modules\Companies\Http\Controllers\CompanyWorkspace\ListCounterpartiesController::class);
            Route::post('/counterparties', \App\Modules\Companies\Http\Controllers\CompanyWorkspace\CreateCounterpartyController::class);

            Route::get('/projects/{projectId}/operations/incomes', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ListIncomesController::class);
            Route::post('/projects/{projectId}/operations/incomes', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\CreateIncomeController::class);
            Route::get('/projects/{projectId}/operations/incomes/{incomeId}', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ShowIncomeController::class);
            Route::patch('/projects/{projectId}/operations/incomes/{incomeId}', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\PatchIncomeController::class);
            Route::post('/projects/{projectId}/operations/incomes/{incomeId}/submit-to-customer-approval', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\IncomeSubmitToCustomerApprovalController::class);
            Route::post('/projects/{projectId}/operations/incomes/{incomeId}/reset-approval', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\IncomeResetApprovalController::class);
            Route::post('/projects/{projectId}/operations/incomes/{incomeId}/complete-waiting', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\IncomeCompleteWaitingController::class);
            Route::post('/projects/{projectId}/operations/incomes/{incomeId}/rollback-completed', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\IncomeRollbackCompletedController::class);

            Route::get('/projects/{projectId}/operations/reports', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ListReportsController::class);
            Route::post('/projects/{projectId}/operations/reports', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\CreateReportController::class);
            Route::get('/projects/{projectId}/operations/reports/{reportId}', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ShowReportController::class);
            Route::patch('/projects/{projectId}/operations/reports/{reportId}', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\PatchReportController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/submit', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\SubmitReportController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/approve-supervisor', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ReportApproveSupervisorController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/reject-supervisor', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ReportRejectSupervisorController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/approve-project-head', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ReportApproveProjectHeadController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/reject-project-head', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ReportRejectProjectHeadController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/approve-customer', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ReportApproveCustomerController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/reject-customer', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ReportRejectCustomerController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/complete-waiting-period', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ReportCompleteWaitingController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/rollback-completed', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ReportRollbackCompletedController::class);
            Route::get('/projects/{projectId}/operations/reports/{reportId}/transfer-links', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\ListReportTransferLinksController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/transfer-links', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\AttachReportTransferLinkController::class);
            Route::delete('/projects/{projectId}/operations/reports/{reportId}/transfer-links/{linkId}', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\DetachReportTransferLinkController::class)
                ->whereNumber('linkId');
        });

    Route::prefix('personal-workspace')
        ->middleware(\App\Modules\Workspaces\Http\Middleware\EnsurePersonalWorkspaceAccess::class)
        ->group(function () {
            Route::get('/context', \App\Modules\Workspaces\Http\Controllers\PersonalWorkspaceContextController::class);

            Route::get('/operations/transfers/history', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ListAggregatedTransfersController::class);
            Route::get('/operations/transfers/pending-count', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\TransferPendingCountController::class);

            Route::get('/operations/history', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ListAggregatedOperationsHistoryController::class);

            Route::get('/operations/incomes/history', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ListAggregatedIncomesController::class);
            Route::get('/operations/incomes/pending-count', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\IncomePendingCountController::class);
            Route::get('/operations/reports/pending-count', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ReportPendingCountController::class);

            Route::get('/companies', \App\Modules\Companies\Http\Controllers\PersonalWorkspace\ListCompaniesController::class);
            Route::get('/projects', \App\Modules\Projects\Http\Controllers\PersonalWorkspace\ListProjectsController::class);
            Route::get('/projects/{projectId}/summary', \App\Modules\Projects\Http\Controllers\PersonalWorkspace\GetProjectSummaryController::class);
            Route::get('/projects/{projectId}/internal-metrics', \App\Modules\Projects\Http\Controllers\PersonalWorkspace\GetProjectInternalMetricsController::class);
            Route::get('/income-by-month', \App\Modules\Projects\Http\Controllers\PersonalWorkspace\ListPersonalIncomeByMonthController::class);

            Route::get('/projects/{projectId}/operations/transfers/recipients', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ListTransferRecipientsController::class);
            Route::get('/projects/{projectId}/operations/transfers', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ListTransfersController::class);
            Route::post('/projects/{projectId}/operations/transfers', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\CreateTransferController::class);
            Route::get('/projects/{projectId}/operations/transfers/{transferId}', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ShowTransferController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/submit-for-approval', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\TransferSubmitForApprovalController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/reset-approval', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\TransferResetApprovalController::class);
            Route::post('/projects/{projectId}/operations/transfers/{transferId}/return-to-created', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\TransferReturnToCreatedController::class);

            Route::get('/projects/{projectId}/operations/incomes', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ListIncomesController::class);
            Route::get('/projects/{projectId}/operations/incomes/{incomeId}', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ShowIncomeController::class);
            Route::post('/projects/{projectId}/operations/incomes/{incomeId}/approve-customer', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\IncomeApproveCustomerController::class);
            Route::post('/projects/{projectId}/operations/incomes/{incomeId}/reject-customer', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\IncomeRejectCustomerController::class);
            Route::post('/projects/{projectId}/operations/incomes/{incomeId}/return-to-customer-approval', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\IncomeReturnToCustomerApprovalController::class);
            Route::post('/projects/{projectId}/operations/incomes/{incomeId}/reset-approval', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\IncomeResetApprovalController::class);

            Route::get('/projects/{projectId}/operations/reports', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ListReportsController::class);
            Route::get('/projects/{projectId}/operations/reports/{reportId}', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ShowReportController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/approve-customer', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ReportApproveCustomerController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/reject-customer', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ReportRejectCustomerController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/rollback-completed', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ReportRollbackCompletedController::class);

            Route::get('/projects/{projectId}/operations/reports/{reportId}/transfer-links', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\ListReportTransferLinksController::class);
            Route::post('/projects/{projectId}/operations/reports/{reportId}/transfer-links', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\AttachReportTransferLinkController::class);
            Route::delete('/projects/{projectId}/operations/reports/{reportId}/transfer-links/{linkId}', \App\Modules\Operations\Http\Controllers\PersonalWorkspace\DetachReportTransferLinkController::class)
                ->whereNumber('linkId');
        });
}); 