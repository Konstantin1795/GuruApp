<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesProjectParticipant;
use App\Modules\Operations\Http\Requests\AttachReportTransferLinkRequest;
use App\Modules\Operations\Http\Resources\ReportTransferLinkResource;
use App\Modules\Operations\Services\ReportTransferLinkService;
use App\Modules\Operations\Services\ReportVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;

final class AttachReportTransferLinkController
{
    use ResolvesProjectParticipant;

    public function __invoke(
        AttachReportTransferLinkRequest $request,
        ProjectVisibilityService $projectVisibility,
        ReportVisibilityService $reportVisibility,
        ReportTransferLinkService $links,
        int $companyId,
        int $projectId,
        int $reportId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessCompanyProject($userId, $companyId, $projectId);

        $report = $reportVisibility->assertCanViewReport($project, $userId, $reportId);
        $actor = $this->projectParticipantForUser($request, $project, $companyId);

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
