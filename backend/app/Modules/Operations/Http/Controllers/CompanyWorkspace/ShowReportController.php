<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Http\Resources\ReportOperationResource;
use App\Modules\Operations\Services\ReportAvailableActionsService;
use App\Modules\Operations\Services\ReportVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ShowReportController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        ReportVisibilityService $reportVisibility,
        ReportAvailableActionsService $availableActions,
        int $companyId,
        int $projectId,
        int $reportId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessCompanyProject($userId, $companyId, $projectId);

        $report = $reportVisibility->assertCanViewReport($project, $userId, $reportId);

        $participant = $reportVisibility->participantForUser($project, $userId);

        $with = [
            'lines',
            'initiator.counterparty.user',
            'recipientParticipant.counterparty.user',
            'customerParticipant.counterparty.user',
            'project',
        ];
        if ($participant === null || $participant->project_role_code !== ProjectRoleCode::CUSTOMER->value) {
            $with = array_merge($with, [
                'transferLinks.transferOperation.sender.counterparty.user',
                'transferLinks.transferOperation.receiver.counterparty.user',
                'transferLinks.transferOperation.project',
            ]);
        }

        $report->load($with);

        return ApiResponse::ok([
            'report' => (new ReportOperationResource($report))->resolve(),
            'available_actions' => $participant !== null
                ? $availableActions->forParticipant($participant, $report)
                : [],
        ]);
    }
}
