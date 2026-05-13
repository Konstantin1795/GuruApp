<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Database\Eloquent\Builder;

final class ReportVisibilityService
{
    public function reportQueryForUser(Project $project, int $userId): Builder
    {
        $query = ReportOperation::query()->where('project_id', $project->id);

        if ($this->userIsCompanyOwnerForProjectCompany($userId, $project)) {
            return $query;
        }

        $participant = $this->participantForUser($project, $userId);
        if (! $participant) {
            return $query->whereRaw('1 = 0');
        }

        if ($participant->project_role_code === ProjectRoleCode::PROJECT_HEAD->value) {
            return $query;
        }

        $pid = (int) $participant->id;

        return $query->where(function (Builder $q) use ($pid): void {
            $q->where('initiator_project_participant_id', $pid)
                ->orWhere('recipient_project_participant_id', $pid)
                ->orWhere('customer_project_participant_id', $pid);
        });
    }

    public function assertCanViewReport(Project $project, int $userId, int $reportId): ReportOperation
    {
        return $this->reportQueryForUser($project, $userId)
            ->whereKey($reportId)
            ->firstOrFail();
    }

    /**
     * @param iterable<int, Project> $projects
     */
    public function reportQueryParticipationOnlyAcrossProjects(iterable $projects, int $userId): Builder
    {
        $projects = is_array($projects) ? $projects : iterator_to_array($projects);
        if ($projects === []) {
            return ReportOperation::query()->whereRaw('1 = 0');
        }

        return ReportOperation::query()->where(function (Builder $outer) use ($projects, $userId): void {
            foreach ($projects as $project) {
                $outer->orWhere(function (Builder $q) use ($project, $userId): void {
                    $sub = $this->reportQueryParticipationOnlyForUser($project, $userId);
                    $q->whereIn('report_operations.id', $sub->select('report_operations.id'));
                });
            }
        });
    }

    public function reportQueryParticipationOnlyForUser(Project $project, int $userId): Builder
    {
        $query = ReportOperation::query()->where('project_id', $project->id);
        $participant = $this->participantForUser($project, $userId);
        if (! $participant) {
            return $query->whereRaw('1 = 0');
        }

        $pid = (int) $participant->id;

        return $query->where(function (Builder $q) use ($pid): void {
            $q->where('initiator_project_participant_id', $pid)
                ->orWhere('recipient_project_participant_id', $pid)
                ->orWhere('customer_project_participant_id', $pid);
        });
    }

    public function participantForUser(Project $project, int $userId): ?ProjectParticipant
    {
        return ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('is_active', true)
            ->whereHas('counterparty', function (Builder $query) use ($userId): void {
                $query->where('user_id', $userId)->where('is_active', true);
            })
            ->first();
    }

    private function userIsCompanyOwnerForProjectCompany(int $userId, Project $project): bool
    {
        return Counterparty::query()
            ->where('company_id', $project->company_id)
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->where('company_role_code', CompanyRoleCode::OWNER->value)
            ->exists();
    }
}
