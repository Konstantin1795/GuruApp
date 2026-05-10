<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Requests\AddProjectParticipantRequest;
use App\Modules\Projects\Http\Resources\ProjectParticipantResource;
use App\Modules\Projects\Services\ProjectParticipantService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;

final class AddProjectParticipantController
{
    public function __invoke(
        AddProjectParticipantRequest $request,
        ProjectParticipantService $service,
        ProjectVisibilityService $visibility,
        int $companyId,
        int $projectId,
    ) {
        $project = $visibility->assertCanManageCompanyProject(
            (int) $request->user()->id,
            $companyId,
            $projectId,
        );

        $payload = $request->validated();

        $participant = $service->add(
            project: $project,
            counterpartyId: (int) $payload['counterparty_id'],
            roleCode: (string) $payload['role'],
            companyId: $companyId,
        );

        $participant->load(['counterparty.user']);

        return ApiResponse::ok(
            ['participant' => (new ProjectParticipantResource($participant))->resolve()],
            status: 201,
        );
    }
}
