<?php

namespace App\Modules\Projects\Http\Controllers\PersonalWorkspace;

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
        int $projectId,
    ) {
        $project = $visibility->assertCanAccessPersonalWorkspaceProject(
            (int) $request->user()->id,
            $projectId,
        );

        $internal->assertCanView($request->user(), $project, null);

        return ApiResponse::ok($internal->buildPayload($project));
    }
}
