<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesPersonalWorkspaceProjectParticipant;
use App\Modules\Operations\Services\ReportLifecycleService;
use App\Modules\Operations\Services\ReportOperationApiPayloadFactory;
use App\Modules\Operations\Services\ReportOperationViewerModeResolver;
use App\Modules\Operations\Services\ReportVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ReportApproveCustomerController
{
    use ResolvesPersonalWorkspaceProjectParticipant;

    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        ReportVisibilityService $reportVisibility,
        ReportLifecycleService $lifecycle,
        ReportOperationViewerModeResolver $viewerMode,
        ReportOperationApiPayloadFactory $reportPayload,
        int $projectId,
        int $reportId,
    ) {
        $user = $request->user();
        $project = $projectVisibility->assertCanAccessPersonalWorkspaceProject((int) $user->id, $projectId);

        $report = $reportVisibility->assertCanViewReport($project, (int) $user->id, $reportId);

        $actor = $this->projectParticipantForPersonalWorkspace($request, $project);

        $updated = $lifecycle->approveByCustomer($project, $report, $actor, $user);

        $mode = $viewerMode->resolve($actor, $updated);

        return ApiResponse::ok([
            'report' => $reportPayload->forReport($updated, $mode),
            'viewer_context' => $mode->value,
        ]);
    }
}
