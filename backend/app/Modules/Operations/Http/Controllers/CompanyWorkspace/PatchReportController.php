<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesProjectParticipant;
use App\Modules\Operations\Http\Requests\PatchReportRequest;
use App\Modules\Operations\Http\Resources\ReportOperationResource;
use App\Modules\Operations\Services\ReportService;
use App\Modules\Operations\Services\ReportVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;

final class PatchReportController
{
    use ResolvesProjectParticipant;

    public function __invoke(
        PatchReportRequest $request,
        ReportService $service,
        ProjectVisibilityService $projectVisibility,
        ReportVisibilityService $reportVisibility,
        int $companyId,
        int $projectId,
        int $reportId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessCompanyProject($userId, $companyId, $projectId);

        $report = $reportVisibility->assertCanViewReport($project, $userId, $reportId);
        $actor = $this->projectParticipantForUser($request, $project, $companyId);

        $updated = $service->updateReport($project, $report, $actor, $request->user(), $request->validated());

        return ApiResponse::ok([
            'report' => (new ReportOperationResource($updated))->toArray($request),
        ]);
    }
}
