<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesProjectParticipant;
use App\Modules\Operations\Http\Requests\RejectReportRequest;
use App\Modules\Operations\Services\ReportLifecycleService;
use App\Modules\Operations\Services\ReportOperationApiPayloadFactory;
use App\Modules\Operations\Services\ReportOperationViewerModeResolver;
use App\Modules\Operations\Services\ReportVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;

final class ReportRejectCustomerController
{
    use ResolvesProjectParticipant;

    public function __invoke(
        RejectReportRequest $request,
        ProjectVisibilityService $projectVisibility,
        ReportVisibilityService $reportVisibility,
        ReportLifecycleService $lifecycle,
        ReportOperationViewerModeResolver $viewerMode,
        ReportOperationApiPayloadFactory $reportPayload,
        int $companyId,
        int $projectId,
        int $reportId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessCompanyProject($userId, $companyId, $projectId);
        $report = $reportVisibility->assertCanViewReport($project, $userId, $reportId);
        $actor = $this->projectParticipantForUser($request, $project, $companyId);

        $updated = $lifecycle->rejectByCustomer(
            $project,
            $report,
            $actor,
            $request->user(),
            (string) $request->validated('comment'),
        );

        $mode = $viewerMode->resolve($actor, $updated);

        return ApiResponse::ok([
            'report' => $reportPayload->forReport($updated, $mode),
            'viewer_context' => $mode->value,
        ]);
    }
}
