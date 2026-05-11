<?php

namespace App\Modules\Projects\Http\Controllers\PersonalWorkspace;

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
        int $projectId,
    ) {
        $project = $visibility->assertCanAccessPersonalWorkspaceProject(
            (int) $request->user()->id,
            $projectId,
        );

        return ApiResponse::ok($summary->build($request->user(), $project, null));
    }
}
