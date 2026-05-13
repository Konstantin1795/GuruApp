<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesProjectParticipant;
use App\Modules\Operations\Http\Requests\CreateReportRequest;
use App\Modules\Operations\Http\Resources\ReportOperationResource;
use App\Modules\Operations\Services\ReportService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Validation\ValidationException;

final class CreateReportController
{
    use ResolvesProjectParticipant;

    public function __invoke(
        CreateReportRequest $request,
        ReportService $service,
        ProjectVisibilityService $visibility,
        int $companyId,
        int $projectId,
    ) {
        $project = $visibility->assertCanAccessCompanyProject(
            (int) $request->user()->id,
            $companyId,
            $projectId,
        );

        if ((int) $project->company_id !== $companyId) {
            throw ValidationException::withMessages(['project' => ['Несоответствие компании и проекта.']]);
        }

        $initiator = $this->projectParticipantForUser($request, $project, $companyId);

        $report = $service->create(
            $project,
            $request->user(),
            $initiator,
            $request->validated(),
        );

        return ApiResponse::ok([
            'report' => (new ReportOperationResource($report))->toArray($request),
        ], status: 201);
    }
}
