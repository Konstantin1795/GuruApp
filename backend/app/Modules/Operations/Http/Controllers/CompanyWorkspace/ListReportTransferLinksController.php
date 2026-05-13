<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Http\Resources\ReportTransferLinkResource;
use App\Modules\Operations\Services\ReportTransferLinkService;
use App\Modules\Operations\Services\ReportVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ListReportTransferLinksController
{
    public function __invoke(
        Request $request,
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

        $participant = $reportVisibility->participantForUser($project, $userId);
        if ($participant !== null && $participant->project_role_code === ProjectRoleCode::CUSTOMER->value) {
            return ApiResponse::ok(['items' => []]);
        }

        $items = $links->listForReport($report);

        return ApiResponse::ok([
            'items' => ReportTransferLinkResource::collection($items)->resolve(),
        ]);
    }
}
