<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Requests\UpdateProjectParticipantRequest;
use App\Modules\Projects\Http\Resources\ProjectParticipantResource;
use App\Modules\Projects\Services\ProjectParticipantService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;

final class UpdateProjectParticipantController
{
    public function __invoke(
        UpdateProjectParticipantRequest $request,
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

        $payload = $request->validated();

        $participant = $service->updateRole(
            project: $project,
            participantId: $participantId,
            newRoleCode: (string) $payload['role'],
        );

        return ApiResponse::ok([
            'participant' => (new ProjectParticipantResource($participant))->resolve(),
        ]);
    }
}
