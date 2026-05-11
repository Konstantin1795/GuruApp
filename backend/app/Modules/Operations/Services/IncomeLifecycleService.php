<?php

namespace App\Modules\Operations\Services;

use App\Models\User;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Models\Operation;
use App\Modules\Operations\Models\OperationStatusHistory;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * ТЗ-06: lifecycle операции INCOME (отдельно от TRANSFER).
 */
final class IncomeLifecycleService
{
    public function __construct(
        private readonly IncomeBalanceService $balanceService,
    ) {}

    public function submitFromCreatedToCustomerApproval(
        Project $project,
        IncomeOperation $income,
        ProjectParticipant $actor,
        User $user,
    ): IncomeOperation {
        $this->assertSameProject($project, $income);
        $this->assertInitiatorActor($income, $actor);

        if ($income->operation_status !== OperationStatus::CREATED) {
            throw ValidationException::withMessages([
                'status' => ['Отправка доступна только из статуса CREATED.'],
            ]);
        }

        if ($income->wallets_applied_at !== null) {
            throw ValidationException::withMessages([
                'income' => ['Операция уже содержит проведённые дельты.'],
            ]);
        }

        return DB::transaction(function () use ($income, $actor, $user): IncomeOperation {
            $fresh = IncomeOperation::query()->whereKey($income->id)->lockForUpdate()->firstOrFail();
            $operation = $this->lockOperation($fresh);

            if ($fresh->operation_status !== OperationStatus::CREATED || $fresh->wallets_applied_at !== null) {
                throw ValidationException::withMessages([
                    'status' => ['Операция уже изменена.'],
                ]);
            }

            $utcNow = Carbon::now('UTC');

            $this->balanceService->applyIncomeDeltas($fresh);

            $fresh->update([
                'operation_status'      => OperationStatus::CUSTOMER_APPROVAL,
                'wallets_applied_at'    => $utcNow,
                'wallets_reverted_at'   => null,
                'waiting_period_started_at' => null,
            ]);

            $operation->update(['operation_status' => OperationStatus::CUSTOMER_APPROVAL]);

            $this->writeHistory(
                $operation,
                OperationStatus::CREATED,
                OperationStatus::CUSTOMER_APPROVAL,
                $actor->id,
                $user,
                null,
            );

            return $fresh->fresh()->load([
                'initiator.counterparty.user',
                'projectHead.counterparty.user',
                'customer.counterparty.user',
                'project',
            ]);
        });
    }

    public function approveByCustomer(
        Project $project,
        IncomeOperation $income,
        ProjectParticipant $actor,
        User $user,
    ): IncomeOperation {
        $this->assertSameProject($project, $income);
        $this->assertCustomerActor($income, $actor);

        if ($income->operation_status !== OperationStatus::CUSTOMER_APPROVAL) {
            throw ValidationException::withMessages([
                'status' => ['Подтверждение доступно только на этапе согласования заказчика.'],
            ]);
        }

        return DB::transaction(function () use ($income, $actor, $user): IncomeOperation {
            $income = IncomeOperation::query()->whereKey($income->id)->lockForUpdate()->firstOrFail();
            $operation = $this->lockOperation($income);
            $utcNow = Carbon::now('UTC');

            $income->update([
                'operation_status'           => OperationStatus::WAITING_24_HOURS,
                'waiting_period_started_at'  => $utcNow,
            ]);

            $operation->update(['operation_status' => OperationStatus::WAITING_24_HOURS]);

            $this->writeHistory(
                $operation,
                OperationStatus::CUSTOMER_APPROVAL,
                OperationStatus::WAITING_24_HOURS,
                $actor->id,
                $user,
                null,
            );

            return $income->fresh()->load([
                'initiator.counterparty.user',
                'projectHead.counterparty.user',
                'customer.counterparty.user',
                'project',
            ]);
        });
    }

    public function rejectByCustomer(
        Project $project,
        IncomeOperation $income,
        ProjectParticipant $actor,
        User $user,
        string $comment,
    ): IncomeOperation {
        $this->assertSameProject($project, $income);
        $this->assertCustomerActor($income, $actor);

        if ($income->operation_status !== OperationStatus::CUSTOMER_APPROVAL) {
            throw ValidationException::withMessages([
                'status' => ['Отклонение доступно только на этапе согласования заказчика.'],
            ]);
        }

        if ($income->wallets_applied_at === null) {
            throw ValidationException::withMessages([
                'income' => ['Нечего откатывать: дельты не применены.'],
            ]);
        }

        return DB::transaction(function () use ($income, $actor, $user, $comment): IncomeOperation {
            $income = IncomeOperation::query()->whereKey($income->id)->lockForUpdate()->firstOrFail();
            $operation = $this->lockOperation($income);

            $this->balanceService->revertIncomeDeltas($income);

            $utcNow = Carbon::now('UTC');

            $operation->update(['operation_status' => OperationStatus::REJECTED]);
            $income->update(['operation_status' => OperationStatus::REJECTED]);

            $this->writeHistory(
                $operation,
                OperationStatus::CUSTOMER_APPROVAL,
                OperationStatus::REJECTED,
                $actor->id,
                $user,
                $comment,
            );

            $operation->update(['operation_status' => OperationStatus::CREATED]);
            $income->update([
                'operation_status'      => OperationStatus::CREATED,
                'wallets_applied_at'    => null,
                'wallets_reverted_at'   => $utcNow,
                'waiting_period_started_at' => null,
            ]);

            $this->writeHistory(
                $operation,
                OperationStatus::REJECTED,
                OperationStatus::CREATED,
                $actor->id,
                $user,
                null,
            );

            return $income->fresh()->load([
                'initiator.counterparty.user',
                'projectHead.counterparty.user',
                'customer.counterparty.user',
                'project',
            ]);
        });
    }

    /**
     * ТЗ-06.1: инициатор сбрасывает подтверждение заказчика — CUSTOMER_APPROVAL → CREATED с откатом дельт.
     */
    public function resetCustomerApprovalToCreated(
        Project $project,
        IncomeOperation $income,
        ProjectParticipant $actor,
        User $user,
    ): IncomeOperation {
        $this->assertSameProject($project, $income);
        $this->assertInitiatorActor($income, $actor);

        if ($income->operation_status !== OperationStatus::CUSTOMER_APPROVAL) {
            throw ValidationException::withMessages([
                'status' => ['Сброс доступен только на этапе согласования заказчика.'],
            ]);
        }

        if ($income->wallets_applied_at === null) {
            throw ValidationException::withMessages([
                'income' => ['Финансовые дельты не применены — сброс не требуется.'],
            ]);
        }

        return DB::transaction(function () use ($income, $actor, $user): IncomeOperation {
            $fresh = IncomeOperation::query()->whereKey($income->id)->lockForUpdate()->firstOrFail();
            $operation = $this->lockOperation($fresh);

            if ($fresh->operation_status !== OperationStatus::CUSTOMER_APPROVAL || $fresh->wallets_applied_at === null) {
                throw ValidationException::withMessages([
                    'status' => ['Операция уже изменена.'],
                ]);
            }

            $this->balanceService->revertIncomeDeltas($fresh);

            $utcNow = Carbon::now('UTC');

            $fresh->update([
                'operation_status'           => OperationStatus::CREATED,
                'wallets_applied_at'         => null,
                'wallets_reverted_at'        => $utcNow,
                'waiting_period_started_at'    => null,
            ]);

            $operation->update(['operation_status' => OperationStatus::CREATED]);

            $this->writeHistory(
                $operation,
                OperationStatus::CUSTOMER_APPROVAL,
                OperationStatus::CREATED,
                $actor->id,
                $user,
                null,
            );

            return $fresh->fresh()->load([
                'initiator.counterparty.user',
                'projectHead.counterparty.user',
                'customer.counterparty.user',
                'project',
            ]);
        });
    }

    public function returnToCustomerApprovalFromWaiting(
        Project $project,
        IncomeOperation $income,
        ProjectParticipant $actor,
        User $user,
    ): IncomeOperation {
        $this->assertSameProject($project, $income);
        $this->assertCustomerActor($income, $actor);

        if ($income->operation_status !== OperationStatus::WAITING_24_HOURS) {
            throw ValidationException::withMessages([
                'status' => ['Возврат доступен только в периоде ожидания 24 часов.'],
            ]);
        }

        return DB::transaction(function () use ($income, $actor, $user): IncomeOperation {
            $income = IncomeOperation::query()->whereKey($income->id)->lockForUpdate()->firstOrFail();
            $operation = $this->lockOperation($income);

            $income->update([
                'operation_status'           => OperationStatus::CUSTOMER_APPROVAL,
                'waiting_period_started_at'    => null,
            ]);

            $operation->update(['operation_status' => OperationStatus::CUSTOMER_APPROVAL]);

            $this->writeHistory(
                $operation,
                OperationStatus::WAITING_24_HOURS,
                OperationStatus::CUSTOMER_APPROVAL,
                $actor->id,
                $user,
                null,
            );

            return $income->fresh()->load([
                'initiator.counterparty.user',
                'projectHead.counterparty.user',
                'customer.counterparty.user',
                'project',
            ]);
        });
    }

    public function completeWaitingByProjectHead(
        Project $project,
        IncomeOperation $income,
        ProjectParticipant $actor,
        User $user,
    ): IncomeOperation {
        $this->assertSameProject($project, $income);
        $this->assertProjectHeadActor($actor);

        if ($income->operation_status !== OperationStatus::WAITING_24_HOURS) {
            throw ValidationException::withMessages([
                'status' => ['Завершение доступно только в периоде ожидания 24 часов.'],
            ]);
        }

        return DB::transaction(function () use ($income, $actor, $user): IncomeOperation {
            $income = IncomeOperation::query()->whereKey($income->id)->lockForUpdate()->firstOrFail();
            $operation = $this->lockOperation($income);

            $income->update(['operation_status' => OperationStatus::COMPLETED]);
            $operation->update(['operation_status' => OperationStatus::COMPLETED]);

            $this->writeHistory(
                $operation,
                OperationStatus::WAITING_24_HOURS,
                OperationStatus::COMPLETED,
                $actor->id,
                $user,
                null,
            );

            return $income->fresh()->load([
                'initiator.counterparty.user',
                'projectHead.counterparty.user',
                'customer.counterparty.user',
                'project',
            ]);
        });
    }

    public function rollbackCompleted(
        Project $project,
        IncomeOperation $income,
        ProjectParticipant $actor,
        User $user,
        string $comment,
    ): IncomeOperation {
        $this->assertSameProject($project, $income);

        $income->loadMissing('initiator');

        if ($income->operation_status !== OperationStatus::COMPLETED) {
            throw ValidationException::withMessages([
                'status' => ['Откат доступен только для завершённой операции.'],
            ]);
        }

        if ($income->wallets_applied_at === null) {
            throw ValidationException::withMessages([
                'income' => ['Дельты не зафиксированы — откат невозможен.'],
            ]);
        }

        $initiator = $income->initiator;
        $role = $initiator->project_role_code;

        if ($role === ProjectRoleCode::PROJECT_HEAD->value) {
            if ((int) $actor->id !== (int) $initiator->id) {
                throw ValidationException::withMessages([
                    'actor' => ['Откат может выполнить только инициатор — руководитель проекта.'],
                ]);
            }
        } elseif ($role === ProjectRoleCode::PARTNER->value) {
            $allowed = (int) $actor->id === (int) $initiator->id
                || $actor->project_role_code === ProjectRoleCode::PROJECT_HEAD->value;
            if (! $allowed) {
                throw ValidationException::withMessages([
                    'actor' => ['Откат может выполнить инициатор-партнёр или руководитель проекта.'],
                ]);
            }
        } else {
            throw ValidationException::withMessages([
                'actor' => ['Откат этой операции для данной роли инициатора не поддерживается.'],
            ]);
        }

        return DB::transaction(function () use ($income, $actor, $user, $comment): IncomeOperation {
            $income = IncomeOperation::query()->whereKey($income->id)->lockForUpdate()->firstOrFail();
            $operation = $this->lockOperation($income);

            $this->balanceService->revertIncomeDeltas($income);

            $utcNow = Carbon::now('UTC');

            $income->update([
                'operation_status'      => OperationStatus::CREATED,
                'wallets_applied_at'    => null,
                'wallets_reverted_at'   => $utcNow,
                'waiting_period_started_at' => null,
            ]);

            $operation->update(['operation_status' => OperationStatus::CREATED]);

            $this->writeHistory(
                $operation,
                OperationStatus::COMPLETED,
                OperationStatus::CREATED,
                $actor->id,
                $user,
                $comment,
            );

            return $income->fresh()->load([
                'initiator.counterparty.user',
                'projectHead.counterparty.user',
                'customer.counterparty.user',
                'project',
            ]);
        });
    }

    public function updateDraftInCreated(
        IncomeOperation $income,
        string $amount,
        ?string $comment,
    ): IncomeOperation {
        if ($income->operation_status !== OperationStatus::CREATED) {
            throw ValidationException::withMessages([
                'status' => ['Редактирование доступно только в статусе CREATED.'],
            ]);
        }

        if ($income->wallets_applied_at !== null) {
            throw ValidationException::withMessages([
                'income' => ['Нельзя редактировать операцию с проведёнными дельтами.'],
            ]);
        }

        $income->update([
            'amount'  => $amount,
            'comment' => $comment,
        ]);

        return $income->fresh()->load([
            'initiator.counterparty.user',
            'projectHead.counterparty.user',
            'customer.counterparty.user',
            'project',
        ]);
    }

    /**
     * @return bool true если статус изменён
     */
    public function autoCompleteWaitingIfDue(IncomeOperation $income): bool
    {
        if ($income->operation_status !== OperationStatus::WAITING_24_HOURS) {
            return false;
        }

        if ($income->waiting_period_started_at === null) {
            return false;
        }

        $startUtc = Carbon::parse($income->waiting_period_started_at)->timezone('UTC');
        if (Carbon::now('UTC')->lessThan($startUtc->copy()->addHours(24))) {
            return false;
        }

        return DB::transaction(function () use ($income): bool {
            /** @var IncomeOperation $fresh */
            $fresh = IncomeOperation::query()->whereKey($income->id)->lockForUpdate()->firstOrFail();

            if ($fresh->operation_status !== OperationStatus::WAITING_24_HOURS) {
                return false;
            }

            if ($fresh->waiting_period_started_at === null) {
                return false;
            }

            $startUtc = Carbon::parse($fresh->waiting_period_started_at)->timezone('UTC');
            if (Carbon::now('UTC')->lessThan($startUtc->copy()->addHours(24))) {
                return false;
            }

            $operation = $this->lockOperation($fresh);

            $fresh->update(['operation_status' => OperationStatus::COMPLETED]);
            $operation->update(['operation_status' => OperationStatus::COMPLETED]);

            $this->writeHistory(
                $operation,
                OperationStatus::WAITING_24_HOURS,
                OperationStatus::COMPLETED,
                null,
                null,
                'Автозавершение по истечении 24 ч (UTC).',
                'Автоматически',
            );

            return true;
        });
    }

    private function assertSameProject(Project $project, IncomeOperation $income): void
    {
        if ((int) $income->project_id !== (int) $project->id) {
            throw ValidationException::withMessages([
                'project' => ['Операция принадлежит другому проекту.'],
            ]);
        }
    }

    private function assertInitiatorActor(IncomeOperation $income, ProjectParticipant $actor): void
    {
        if ((int) $income->initiator_project_participant_id !== (int) $actor->id) {
            throw ValidationException::withMessages([
                'actor' => ['Действие доступно только инициатору операции.'],
            ]);
        }
    }

    private function assertCustomerActor(IncomeOperation $income, ProjectParticipant $actor): void
    {
        if ($actor->project_role_code !== ProjectRoleCode::CUSTOMER->value) {
            throw ValidationException::withMessages([
                'actor' => ['Действие доступно только заказчику проекта.'],
            ]);
        }

        if ((int) $actor->id !== (int) $income->customer_project_participant_id) {
            throw ValidationException::withMessages([
                'actor' => ['Вы не являетесь заказчиком по этой операции.'],
            ]);
        }
    }

    private function assertProjectHeadActor(ProjectParticipant $actor): void
    {
        if ($actor->project_role_code !== ProjectRoleCode::PROJECT_HEAD->value) {
            throw ValidationException::withMessages([
                'actor' => ['Действие доступно только руководителю проекта.'],
            ]);
        }
    }

    private function lockOperation(IncomeOperation $income): Operation
    {
        /** @var Operation $op */
        $op = Operation::query()->whereKey($income->operation_id)->lockForUpdate()->firstOrFail();

        return $op;
    }

    private function writeHistory(
        Operation $operation,
        ?OperationStatus $from,
        OperationStatus $to,
        ?int $changedByParticipantId,
        ?User $user,
        ?string $comment,
        ?string $authorFullNameOverride = null,
    ): void {
        OperationStatusHistory::query()->create([
            'operation_id'                      => $operation->id,
            'from_status'                       => $from,
            'to_status'                         => $to,
            'changed_by_project_participant_id' => $changedByParticipantId,
            'author_user_id'                    => $user?->id,
            'author_full_name'                  => $authorFullNameOverride ?? $user?->name,
            'comment'                           => $comment,
        ]);
    }
}
