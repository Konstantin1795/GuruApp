<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\ProjectParticipantService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class RemoveProjectParticipantController
{
    public function __invoke(
        Request $request,
        ProjectParticipantService $service,
        ProjectVisibilityService $visibility,
        int $companyId,
        int $projectId,
        int $participantId,
    ) {
        $project = $visibility->assertCanManageCompanyProject(
            (int) $request->user()->id,
            $companyId,
            $projectId,
        );

        $service->remove($project, $participantId);

        return ApiResponse::ok();
    }
}
