<?php

namespace App\Modules\Workspaces\Http\Controllers;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class PersonalWorkspaceContextController
{
    public function __invoke(Request $request)
    {
        $userId = (int) $request->user()->id;

        $companyIds = Counterparty::query()
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->pluck('company_id')
            ->unique()
            ->values()
            ->all();

        $projectIds = ProjectParticipant::query()
            ->whereHas('counterparty', function ($q) use ($userId) {
                $q->where('user_id', $userId);
            })
            ->where('is_active', true)
            ->pluck('project_id')
            ->unique()
            ->values()
            ->all();

        return ApiResponse::ok([
            'user_id' => $userId,
            'company_ids' => $companyIds,
            'project_ids' => $projectIds,
        ]);
    }
}

