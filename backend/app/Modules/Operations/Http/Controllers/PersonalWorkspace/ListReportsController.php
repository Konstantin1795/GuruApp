<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Services\ReportOperationApiPayloadFactory;
use App\Modules\Operations\Services\ReportOperationViewerModeResolver;
use App\Modules\Operations\Services\ReportVisibilityService;
use App\Modules\Operations\Support\ReportOperationListSearchFilter;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ListReportsController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        ReportVisibilityService $reportVisibility,
        ReportOperationViewerModeResolver $viewerMode,
        ReportOperationApiPayloadFactory $reportPayload,
        int $projectId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessPersonalWorkspaceProject($userId, $projectId);

        $participant = $reportVisibility->participantForUser($project, $userId);

        $query = $reportVisibility
            ->reportQueryForUser($project, $userId)
            ->with(['initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project']);

        ReportOperationListSearchFilter::apply($query, (string) $request->query('search', ''));

        $items = $query->orderByDesc('id')->get();

        $reports = [];
        foreach ($items as $report) {
            $mode = $viewerMode->resolve($participant, $report);
            $reports[] = $reportPayload->forReport($report, $mode);
        }

        return ApiResponse::ok([
            'reports' => $reports,
        ]);
    }
}
