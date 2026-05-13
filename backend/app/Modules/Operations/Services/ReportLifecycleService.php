<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Models\User;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Operations\Models\ReportOperationStatusHistory;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * ТЗ-10C: lifecycle REPORT без записи в общую таблицу {@see \App\Modules\Operations\Models\Operation}.
 */
final class ReportLifecycleService
{
    public function __construct(
        private readonly ReportBalanceService $balanceService,
    ) {}

    public function submitFromCreated(Project $project, ReportOperation $report, ProjectParticipant $actor, User $user): ReportOperation
    {
        $this->assertSameProject($project, $report);
        $this->assertInitiator($report, $actor);

        if ($report->operation_status !== OperationStatus::CREATED) {
            throw ValidationException::withMessages(['status' => ['Отправка доступна только из CREATED.']]);
        }

        return DB::transaction(function () use ($project, $report, $actor, $user): ReportOperation {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();
            if ($fresh->operation_status !== OperationStatus::CREATED) {
                throw ValidationException::withMessages(['status' => ['Операция уже изменена.']]);
            }

            $initiator = $fresh->initiator;
            $isHead = $initiator->project_role_code === ProjectRoleCode::PROJECT_HEAD->value;

            if ($isHead) {
                $this->balanceService->applyReportDeltas($fresh);
                $fresh->update(['operation_status' => OperationStatus::CUSTOMER_APPROVAL]);
                $this->writeHistory($fresh, OperationStatus::CREATED, OperationStatus::CUSTOMER_APPROVAL, $actor->id, $user, null);
            } elseif ($this->projectHasActiveSupervisor($project->id)) {
                $fresh->update(['operation_status' => OperationStatus::SUPERVISOR_APPROVAL]);
                $this->writeHistory($fresh, OperationStatus::CREATED, OperationStatus::SUPERVISOR_APPROVAL, $actor->id, $user, null);
            } else {
                $fresh->update(['operation_status' => OperationStatus::PROJECT_HEAD_APPROVAL]);
                $this->writeHistory($fresh, OperationStatus::CREATED, OperationStatus::PROJECT_HEAD_APPROVAL, $actor->id, $user, null);
            }

            return $fresh->fresh()->load(['initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project', 'lines']);
        });
    }

    public function approveBySupervisor(
        Project $project,
        ReportOperation $report,
        ProjectParticipant $actor,
        User $user,
    ): ReportOperation {
        $this->assertSameProject($project, $report);
        $this->assertSupervisor($actor);

        if ($report->operation_status !== OperationStatus::SUPERVISOR_APPROVAL) {
            throw ValidationException::withMessages(['status' => ['Недопустимый статус для технадзора.']]);
        }

        return DB::transaction(function () use ($report, $actor, $user): ReportOperation {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();
            if ($fresh->operation_status !== OperationStatus::SUPERVISOR_APPROVAL) {
                throw ValidationException::withMessages(['status' => ['Операция уже изменена.']]);
            }
            $fresh->update(['operation_status' => OperationStatus::PROJECT_HEAD_APPROVAL]);
            $this->writeHistory($fresh, OperationStatus::SUPERVISOR_APPROVAL, OperationStatus::PROJECT_HEAD_APPROVAL, $actor->id, $user, null);

            return $fresh->fresh()->load(['initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project', 'lines']);
        });
    }

    public function rejectBySupervisor(
        Project $project,
        ReportOperation $report,
        ProjectParticipant $actor,
        User $user,
        string $comment,
    ): ReportOperation {
        $this->assertComment($comment);
        $this->assertSameProject($project, $report);
        $this->assertSupervisor($actor);

        if ($report->operation_status !== OperationStatus::SUPERVISOR_APPROVAL) {
            throw ValidationException::withMessages(['status' => ['Недопустимый статус.']]);
        }

        return DB::transaction(function () use ($report, $actor, $user, $comment): ReportOperation {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();
            if ($fresh->operation_status !== OperationStatus::SUPERVISOR_APPROVAL) {
                throw ValidationException::withMessages(['status' => ['Операция уже изменена.']]);
            }
            $fresh->update(['operation_status' => OperationStatus::CREATED]);
            $this->writeHistory($fresh, OperationStatus::SUPERVISOR_APPROVAL, OperationStatus::CREATED, $actor->id, $user, $comment);

            return $fresh->fresh()->load(['initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project', 'lines']);
        });
    }

    public function approveByProjectHead(
        Project $project,
        ReportOperation $report,
        ProjectParticipant $actor,
        User $user,
    ): ReportOperation {
        $this->assertSameProject($project, $report);
        $this->assertProjectHead($actor);

        if ($report->operation_status !== OperationStatus::PROJECT_HEAD_APPROVAL) {
            throw ValidationException::withMessages(['status' => ['Подтверждение РП доступно только в PROJECT_HEAD_APPROVAL.']]);
        }

        return DB::transaction(function () use ($report, $actor, $user): ReportOperation {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();
            if ($fresh->operation_status !== OperationStatus::PROJECT_HEAD_APPROVAL) {
                throw ValidationException::withMessages(['status' => ['Операция уже изменена.']]);
            }

            if ($fresh->wallets_applied_at === null) {
                $this->balanceService->applyReportDeltas($fresh);
            }

            $fresh->update(['operation_status' => OperationStatus::CUSTOMER_APPROVAL]);
            $this->writeHistory($fresh, OperationStatus::PROJECT_HEAD_APPROVAL, OperationStatus::CUSTOMER_APPROVAL, $actor->id, $user, null);

            return $fresh->fresh()->load(['initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project', 'lines']);
        });
    }

    public function rejectByProjectHead(
        Project $project,
        ReportOperation $report,
        ProjectParticipant $actor,
        User $user,
        string $comment,
    ): ReportOperation {
        $this->assertComment($comment);
        $this->assertSameProject($project, $report);
        $this->assertProjectHead($actor);

        if ($report->operation_status !== OperationStatus::PROJECT_HEAD_APPROVAL) {
            throw ValidationException::withMessages(['status' => ['Недопустимый статус.']]);
        }

        return DB::transaction(function () use ($report, $actor, $user, $comment): ReportOperation {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();
            if ($fresh->operation_status !== OperationStatus::PROJECT_HEAD_APPROVAL) {
                throw ValidationException::withMessages(['status' => ['Операция уже изменена.']]);
            }
            $fresh->update(['operation_status' => OperationStatus::CREATED]);
            $this->writeHistory($fresh, OperationStatus::PROJECT_HEAD_APPROVAL, OperationStatus::CREATED, $actor->id, $user, $comment);

            return $fresh->fresh()->load(['initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project', 'lines']);
        });
    }

    public function approveByCustomer(
        Project $project,
        ReportOperation $report,
        ProjectParticipant $actor,
        User $user,
    ): ReportOperation {
        $this->assertSameProject($project, $report);
        $this->assertCustomer($report, $actor);

        if ($report->operation_status !== OperationStatus::CUSTOMER_APPROVAL) {
            throw ValidationException::withMessages(['status' => ['Подтверждение заказчика недоступно.']]);
        }

        return DB::transaction(function () use ($report, $actor, $user): ReportOperation {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();
            if ($fresh->operation_status !== OperationStatus::CUSTOMER_APPROVAL) {
                throw ValidationException::withMessages(['status' => ['Операция уже изменена.']]);
            }

            $utcNow = Carbon::now('UTC');
            $fresh->update([
                'operation_status'          => OperationStatus::WAITING_24_HOURS,
                'waiting_period_started_at' => $utcNow,
            ]);
            $this->writeHistory($fresh, OperationStatus::CUSTOMER_APPROVAL, OperationStatus::WAITING_24_HOURS, $actor->id, $user, null);

            return $fresh->fresh()->load(['initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project', 'lines']);
        });
    }

    public function rejectByCustomer(
        Project $project,
        ReportOperation $report,
        ProjectParticipant $actor,
        User $user,
        string $comment,
    ): ReportOperation {
        $this->assertComment($comment);
        $this->assertSameProject($project, $report);
        $this->assertCustomer($report, $actor);

        if ($report->operation_status !== OperationStatus::CUSTOMER_APPROVAL) {
            throw ValidationException::withMessages(['status' => ['Отклонение заказчика недоступно.']]);
        }

        return DB::transaction(function () use ($report, $actor, $user, $comment): ReportOperation {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();
            if ($fresh->operation_status !== OperationStatus::CUSTOMER_APPROVAL) {
                throw ValidationException::withMessages(['status' => ['Операция уже изменена.']]);
            }

            if ($fresh->wallets_applied_at !== null) {
                $this->balanceService->revertReportDeltas($fresh);
            }

            $fresh->update([
                'operation_status'          => OperationStatus::PROJECT_HEAD_APPROVAL,
                'waiting_period_started_at' => null,
            ]);
            $this->writeHistory($fresh, OperationStatus::CUSTOMER_APPROVAL, OperationStatus::PROJECT_HEAD_APPROVAL, $actor->id, $user, $comment);

            return $fresh->fresh()->load(['initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project', 'lines']);
        });
    }

    public function completeWaitingPeriod(
        Project $project,
        ReportOperation $report,
        ProjectParticipant $actor,
        User $user,
    ): ReportOperation {
        $this->assertSameProject($project, $report);
        $this->assertProjectHead($actor);

        if ($report->operation_status !== OperationStatus::WAITING_24_HOURS) {
            throw ValidationException::withMessages(['status' => ['Завершение 24ч доступно только в WAITING_24_HOURS.']]);
        }

        return DB::transaction(function () use ($report, $actor, $user): ReportOperation {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();
            if ($fresh->operation_status !== OperationStatus::WAITING_24_HOURS) {
                throw ValidationException::withMessages(['status' => ['Операция уже изменена.']]);
            }

            $utcNow = Carbon::now('UTC');
            $fresh->update([
                'operation_status' => OperationStatus::COMPLETED,
                'completed_at'     => $utcNow,
            ]);
            $this->writeHistory($fresh, OperationStatus::WAITING_24_HOURS, OperationStatus::COMPLETED, $actor->id, $user, null);

            return $fresh->fresh()->load(['initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project', 'lines']);
        });
    }

    public function rollbackCompleted(
        Project $project,
        ReportOperation $report,
        ProjectParticipant $actor,
        User $user,
        string $comment,
    ): ReportOperation {
        $this->assertComment($comment);
        $this->assertSameProject($project, $report);
        $this->assertProjectHead($actor);

        if ($report->operation_status !== OperationStatus::COMPLETED) {
            throw ValidationException::withMessages(['status' => ['Откат доступен только из COMPLETED.']]);
        }

        return DB::transaction(function () use ($report, $actor, $user, $comment): ReportOperation {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();
            if ($fresh->operation_status !== OperationStatus::COMPLETED) {
                throw ValidationException::withMessages(['status' => ['Операция уже изменена.']]);
            }

            if ($fresh->wallets_applied_at !== null) {
                $this->balanceService->revertReportDeltas($fresh);
            }

            $fresh->update([
                'operation_status'          => OperationStatus::PROJECT_HEAD_APPROVAL,
                'completed_at'              => null,
                'waiting_period_started_at' => null,
            ]);
            $this->writeHistory($fresh, OperationStatus::COMPLETED, OperationStatus::PROJECT_HEAD_APPROVAL, $actor->id, $user, $comment);

            return $fresh->fresh()->load(['initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project', 'lines']);
        });
    }

    public function autoCompleteWaitingIfDue(ReportOperation $report): bool
    {
        if ($report->operation_status !== OperationStatus::WAITING_24_HOURS || $report->waiting_period_started_at === null) {
            return false;
        }

        $due = $report->waiting_period_started_at->copy()->addHours(24);
        if (Carbon::now('UTC')->lt($due)) {
            return false;
        }

        DB::transaction(function () use ($report): void {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();
            if ($fresh->operation_status !== OperationStatus::WAITING_24_HOURS) {
                return;
            }
            $dueInner = $fresh->waiting_period_started_at?->copy()->addHours(24);
            if ($dueInner === null || Carbon::now('UTC')->lt($dueInner)) {
                return;
            }
            $utcNow = Carbon::now('UTC');
            $fresh->update([
                'operation_status' => OperationStatus::COMPLETED,
                'completed_at'       => $utcNow,
            ]);
            $this->writeHistory($fresh, OperationStatus::WAITING_24_HOURS, OperationStatus::COMPLETED, null, null, 'auto:24h');
        });

        return true;
    }

    private function projectHasActiveSupervisor(int $projectId): bool
    {
        return ProjectParticipant::query()
            ->where('project_id', $projectId)
            ->where('project_role_code', ProjectRoleCode::SUPERVISOR->value)
            ->where('is_active', true)
            ->whereRaw('lower(level) = ?', ['first'])
            ->exists();
    }

    private function writeHistory(
        ReportOperation $report,
        OperationStatus $from,
        OperationStatus $to,
        ?int $changedByParticipantId,
        ?User $user,
        ?string $comment,
    ): void {
        ReportOperationStatusHistory::query()->create([
            'report_operation_id'               => $report->id,
            'from_status'                       => $from,
            'to_status'                         => $to,
            'changed_by_project_participant_id' => $changedByParticipantId,
            'author_user_id'                    => $user?->id,
            'author_full_name'                  => $user?->name,
            'comment'                           => $comment,
            'created_at'                        => Carbon::now('UTC'),
        ]);
    }

    private function assertSameProject(Project $project, ReportOperation $report): void
    {
        if ((int) $report->project_id !== (int) $project->id) {
            throw ValidationException::withMessages(['project' => ['Отчёт относится к другому проекту.']]);
        }
    }

    private function assertInitiator(ReportOperation $report, ProjectParticipant $actor): void
    {
        if ((int) $report->initiator_project_participant_id !== (int) $actor->id) {
            throw ValidationException::withMessages(['actor' => ['Только инициатор может отправить отчёт.']]);
        }
    }

    private function assertProjectHead(ProjectParticipant $actor): void
    {
        if ($actor->project_role_code !== ProjectRoleCode::PROJECT_HEAD->value) {
            throw ValidationException::withMessages(['actor' => ['Действие доступно только руководителю проекта.']]);
        }
    }

    private function assertSupervisor(ProjectParticipant $actor): void
    {
        if ($actor->project_role_code !== ProjectRoleCode::SUPERVISOR->value) {
            throw ValidationException::withMessages(['actor' => ['Действие доступно только технадзору.']]);
        }
    }

    private function assertCustomer(ReportOperation $report, ProjectParticipant $actor): void
    {
        if ((int) $report->customer_project_participant_id !== (int) $actor->id) {
            throw ValidationException::withMessages(['actor' => ['Действие доступно только заказчику проекта.']]);
        }
    }

    private function assertComment(string $comment): void
    {
        if (trim($comment) === '') {
            throw ValidationException::withMessages(['comment' => ['Комментарий обязателен.']]);
        }
    }
}
