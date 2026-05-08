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

            Route::get('/companies/current', \App\Modules\Companies\Http\Controllers\CompanyWorkspace\CurrentCompanyController::class);
            Route::get('/projects', \App\Modules\Projects\Http\Controllers\CompanyWorkspace\ListProjectsController::class);
            Route::get('/counterparties', \App\Modules\Companies\Http\Controllers\CompanyWorkspace\ListCounterpartiesController::class);
        });

    Route::prefix('personal-workspace')
        ->middleware(\App\Modules\Workspaces\Http\Middleware\EnsurePersonalWorkspaceAccess::class)
        ->group(function () {
            Route::get('/context', \App\Modules\Workspaces\Http\Controllers\PersonalWorkspaceContextController::class);

            Route::get('/companies', \App\Modules\Companies\Http\Controllers\PersonalWorkspace\ListCompaniesController::class);
            Route::get('/projects', \App\Modules\Projects\Http\Controllers\PersonalWorkspace\ListProjectsController::class);
        });
});