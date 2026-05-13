<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesPersonalWorkspaceProjectParticipant;
use App\Modules\Operations\Services\ReportTransferLinkService;
use App\Modules\Operations\Services\ReportVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class DetachReportTransferLinkController
{
    use ResolvesPersonalWorkspaceProjectParticipant;

    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        ReportVisibilityService $reportVisibility,
        ReportTransferLinkService $links,
        int $projectId,
        int $reportId,
        int $linkId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessPersonalWorkspaceProject($userId, $projectId);

        $report = $reportVisibility->assertCanViewReport($project, $userId, $reportId);
        $actor = $this->projectParticipantForPersonalWorkspace($request, $project);

        $links->detach($report, $actor, $linkId);

        return ApiResponse::ok([]);
    }
}
