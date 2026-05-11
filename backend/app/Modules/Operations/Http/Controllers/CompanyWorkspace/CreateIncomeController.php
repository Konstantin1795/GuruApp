<?php

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Http\Concerns\ResolvesProjectParticipant;
use App\Modules\Operations\Http\Requests\CreateIncomeRequest;
use App\Modules\Operations\Http\Resources\IncomeOperationResource;
use App\Modules\Operations\Services\IncomeService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Validation\ValidationException;

final class CreateIncomeController
{
    use ResolvesProjectParticipant;

    public function __invoke(
        CreateIncomeRequest $request,
        IncomeService $service,
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
        $payload = $request->validated();

        $income = $service->create(
            project: $project,
            initiator: $initiator,
            amount: (string) $payload['amount'],
            comment: isset($payload['comment']) ? (string) $payload['comment'] : null,
            initiatorUser: $request->user(),
        );

        return ApiResponse::ok([
            'income' => (new IncomeOperationResource($income))->toArray($request),
        ], status: 201);
    }
}
