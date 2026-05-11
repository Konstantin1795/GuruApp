<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\ProjectInternalMetricsService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class GetProjectInternalMetricsController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $visibility,
        ProjectInternalMetricsService $internal,
        int $companyId,
        int $projectId,
    ) {
        $project = $visibility->assertCanAccessCompanyProject(
            (int) $request->user()->id,
            $companyId,
            $projectId,
        );

        $internal->assertCanView($request->user(), $project, $companyId);

        return ApiResponse::ok($internal->buildPayload($project));
    }
}
