<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Resources\ReportOperationResource;
use App\Modules\Operations\Services\ReportVisibilityService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ListReportsController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        ReportVisibilityService $reportVisibility,
        int $companyId,
        int $projectId,
    ) {
        $userId = (int) $request->user()->id;
        $project = $projectVisibility->assertCanAccessCompanyProject($userId, $companyId, $projectId);

        $items = $reportVisibility
            ->reportQueryForUser($project, $userId)
            ->with(['initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project'])
            ->orderByDesc('id')
            ->get();

        return ApiResponse::ok([
            'reports' => ReportOperationResource::collection($items)->resolve(),
        ]);
    }
}
