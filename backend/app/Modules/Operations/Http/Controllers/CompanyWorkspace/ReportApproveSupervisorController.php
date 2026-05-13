<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesProjectParticipant;
use App\Modules\Operations\Http\Resources\ReportOperationResource;
use App\Modules\Operations\Services\ReportLifecycleService;
use App\Modules\Operations\Services\ReportVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ReportApproveSupervisorController
{
    use ResolvesProjectParticipant;

    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        ReportVisibilityService $reportVisibility,
        ReportLifecycleService $lifecycle,
        int $companyId,
        int $projectId,
        int $reportId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessCompanyProject($userId, $companyId, $projectId);
        $report = $reportVisibility->assertCanViewReport($project, $userId, $reportId);
        $actor = $this->projectParticipantForUser($request, $project, $companyId);

        $updated = $lifecycle->approveBySupervisor($project, $report, $actor, $request->user());

        return ApiResponse::ok(['report' => (new ReportOperationResource($updated))->resolve()]);
    }
}
