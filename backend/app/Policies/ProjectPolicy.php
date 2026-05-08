<?php

namespace App\Policies;

use App\Models\User;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;

final class ProjectPolicy
{
    public function view(User $user, Project $project): bool
    {
        $counterpartyIds = Counterparty::query()
            ->where('user_id', $user->id)
            ->pluck('id');

        return ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->whereIn('counterparty_id', $counterpartyIds)
            ->where('is_active', true)
            ->exists();
    }
}

