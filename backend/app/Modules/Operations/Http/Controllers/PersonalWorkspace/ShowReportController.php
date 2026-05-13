<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\ReportOperationViewerMode;
use App\Modules\Operations\Services\ReportAvailableActionsService;
use App\Modules\Operations\Services\ReportOperationApiPayloadFactory;
use App\Modules\Operations\Services\ReportOperationViewerModeResolver;
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
        ReportOperationViewerModeResolver $viewerMode,
        ReportOperationApiPayloadFactory $reportPayload,
        int $projectId,
        int $reportId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessPersonalWorkspaceProject($userId, $projectId);

        $report = $reportVisibility->assertCanViewReport($project, $userId, $reportId);

        $participant = $reportVisibility->participantForUser($project, $userId);

        $with = [
            'lines',
            'statusHistories',
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

        $mode = $viewerMode->resolve($participant, $report);

        if ($mode === ReportOperationViewerMode::SecondOrderRecipient
            && $report->relationLoaded('transferLinks')) {
            $uid = (int) $request->user()->id;
            $report->setRelation(
                'transferLinks',
                $report->transferLinks
                    ->filter(function ($link) use ($uid): bool {
                        $t = $link->transferOperation;
                        if ($t === null) {
                            return false;
                        }
                        $senderUid = (int) ($t->sender?->counterparty?->user_id ?? 0);
                        $receiverUid = (int) ($t->receiver?->counterparty?->user_id ?? 0);

                        return $senderUid === $uid || $receiverUid === $uid;
                    })
                    ->values(),
            );
        }

        return ApiResponse::ok([
            'report' => $reportPayload->forReport($report, $mode),
            'viewer_context' => $mode->value,
            'available_actions' => $participant !== null
                ? $availableActions->forParticipant($participant, $report)
                : [],
        ]);
    }
}
