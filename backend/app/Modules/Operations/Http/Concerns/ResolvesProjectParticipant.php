<?php

namespace App\Modules\Operations\Http\Concerns;

use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Http\Request;

trait ResolvesProjectParticipant
{
    protected function projectParticipantForUser(Request $request, Project $project, int $companyId): ProjectParticipant
    {
        return ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('is_active', true)
            ->whereHas('counterparty', function ($query) use ($request, $companyId): void {
                $query->where('company_id', $companyId)
                    ->where('user_id', (int) $request->user()->id)
                    ->where('is_active', true);
            })
            ->firstOrFail();
    }
}
