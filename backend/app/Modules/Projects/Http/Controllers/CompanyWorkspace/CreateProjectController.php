<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Requests\CreateProjectRequest;
use App\Modules\Projects\Http\Resources\ProjectResource;
use App\Modules\Projects\Services\CreateProjectService;
use App\Support\Http\ApiResponse;

final class CreateProjectController
{
    public function __invoke(CreateProjectRequest $request, CreateProjectService $createProject, int $companyId)
    {
        $user = $request->user();
        if (! $user) {
            abort(401, 'Unauthenticated.');
        }

        $project = $createProject->createFromCompanyWorkspace($user, $companyId, $request->validated());

        return ApiResponse::ok([
            'project' => (new ProjectResource($project))->resolve(),
        ]);
    }
}
