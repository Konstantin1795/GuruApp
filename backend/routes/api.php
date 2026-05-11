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

            Route::get('/companies/current', \App\Modules\Companies\Http\Controllers\CompanyWorkspace\CurrentCompanyController::class);
            Route::get('/projects', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ListProjectsController::class);
            Route::post('/projects', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\CreateProjectController::class);
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
            Route::post('/projects/{projectId}/operations/incomes/{incomeId}/complete-waiting', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\IncomeCompleteWaitingController::class);
            Route::post('/projects/{projectId}/operations/incomes/{incomeId}/rollback-completed', \App\Modules\Operations\Http\Controllers\CompanyWorkspace\IncomeRollbackCompletedController::class);
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

            Route::get('/companies', \App\Modules\Companies\Http\Controllers\PersonalWorkspace\ListCompaniesController::class);
            Route::get('/projects', \App\Modules\Projects\Http\Controllers\PersonalWorkspace\ListProjectsController::class);
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
        });
}); 