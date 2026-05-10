<?php

namespace App\Modules\Operations\Http\Concerns;

use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Http\Request;

trait ResolvesPersonalWorkspaceProjectParticipant
{
    protected function projectParticipantForPersonalWorkspace(Request $request, Project $project): ProjectParticipant
    {
        return ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('is_active', true)
            ->whereHas('counterparty', function ($query) use ($request): void {
                $query->where('user_id', (int) $request->user()->id)
                    ->where('is_active', true);
            })
            ->firstOrFail();
    }
}
