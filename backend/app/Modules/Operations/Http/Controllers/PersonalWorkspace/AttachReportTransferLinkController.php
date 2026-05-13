<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesPersonalWorkspaceProjectParticipant;
use App\Modules\Operations\Http\Requests\AttachReportTransferLinkRequest;
use App\Modules\Operations\Http\Resources\ReportTransferLinkResource;
use App\Modules\Operations\Services\ReportTransferLinkService;
use App\Modules\Operations\Services\ReportVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;

final class AttachReportTransferLinkController
{
    use ResolvesPersonalWorkspaceProjectParticipant;

    public function __invoke(
        AttachReportTransferLinkRequest $request,
        ProjectVisibilityService $projectVisibility,
        ReportVisibilityService $reportVisibility,
        ReportTransferLinkService $links,
        int $projectId,
        int $reportId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessPersonalWorkspaceProject($userId, $projectId);

        $report = $reportVisibility->assertCanViewReport($project, $userId, $reportId);
        $actor = $this->projectParticipantForPersonalWorkspace($request, $project);

        $validated = $request->validated();
        $link = $links->attachByTransferOperationNumber(
            $report,
            $actor,
            $request->user(),
            (string) $validated['operation_number'],
        );

        return ApiResponse::ok([
            'link' => (new ReportTransferLinkResource($link))->toArray($request),
        ], status: 201);
    }
}
