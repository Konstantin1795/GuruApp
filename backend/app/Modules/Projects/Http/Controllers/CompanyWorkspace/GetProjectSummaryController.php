<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\ProjectSummaryResponseService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class GetProjectSummaryController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $visibility,
        ProjectSummaryResponseService $summary,
        int $companyId,
        int $projectId,
    ) {
        $project = $visibility->assertCanAccessCompanyProject(
            (int) $request->user()->id,
            $companyId,
            $projectId,
        );

        return ApiResponse::ok($summary->build($request->user(), $project, $companyId));
    }
}
