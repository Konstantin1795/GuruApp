<?php

namespace App\Modules\Operations\Services;

use App\Models\User;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\Operation;
use App\Modules\Operations\Models\OperationStatusHistory;
use App\Modules\Operations\Models\TransferOperation;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\WalletService;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * ТЗ-05.2 v3: переходы статусов и финансы для TRANSFER.
 *
 * Инвариант GURU: любые дельты по кошелькам только через {@see TransferBalanceService}
 * внутри методов этого класса (в транзакции). Менять порядок смены статуса и проведения
 * дельт без обновления ТЗ-05.2 и регрессионных тестов нельзя.
 */
final class TransferLifecycleService
{
    public function __construct(
        private readonly TransferBalanceService $balanceService,
        private readonly WalletService $walletService,
    ) {}

    public function approveByProjectHead(
        Project $project,
        TransferOperation $transfer,
        ProjectParticipant $actor,
        User $user,
    ): TransferOperation {
        $this->assertSameProject($project, $transfer);
        $this->assertProjectHeadActor($actor);

        if ($transfer->operation_status !== OperationStatus::PROJECT_HEAD_APPROVAL) {
            throw ValidationException::withMessages([
                'status' => ['Операция не ожидает подтверждения руководителя проекта.'],
            ]);
        }

        if ($transfer->wallets_applied_at !== null) {
            throw ValidationException::withMessages([
                'transfer' => ['Финансовые дельты уже применены.'],
            ]);
        }

        return DB::transaction(function () use ($transfer, $actor, $user) {
            $operation = $this->lockOperation($transfer);
            [$senderW, $receiverW] = $this->lockTransferWallets($transfer);

            $this->balanceService->applyTransfer(
                $senderW,
                $receiverW,
                $transfer->transfer_target_type,
                (string) $transfer->amount,
            );

            /** @var Carbon $utcNow Время начала 24ч в UTC (ТЗ-05.2 §17–19). */
            $utcNow = Carbon::now('UTC');

            $transfer->update([
                'operation_status'            => OperationStatus::WAITING_24_HOURS,
                'wallets_applied_at'          => $utcNow,
                'wallets_reverted_at'         => null,
                'waiting_period_started_at'   => $utcNow,
            ]);

            $operation->update(['operation_status' => OperationStatus::WAITING_24_HOURS]);

            $this->writeHistory(
                $operation,
                OperationStatus::PROJECT_HEAD_APPROVAL,
                OperationStatus::WAITING_24_HOURS,
                $actor->id,
                $user,
                null,
            );

            return $transfer->fresh()->load(['sender.counterparty.user', 'receiver.counterparty.user']);
        });
    }

    public function rejectByProjectHead(
        Project $project,
        TransferOperation $transfer,
        ProjectParticipant $actor,
        User $user,
        string $reason,
    ): TransferOperation {
        $this->assertSameProject($project, $transfer);
        $this->assertProjectHeadActor($actor);

        if ($transfer->operation_status !== OperationStatus::PROJECT_HEAD_APPROVAL) {
            throw ValidationException::withMessages([
                'status' => ['Операция не ожидает подтверждения руководителя проекта.'],
            ]);
        }

        if ($transfer->wallets_applied_at !== null) {
            throw ValidationException::withMessages([
                'transfer' => ['Невозможно отклонить: дельты уже применены.'],
            ]);
        }

        return DB::transaction(function () use ($transfer, $actor, $user, $reason) {
            $operation = $this->lockOperation($transfer);

            $operation->update(['operation_status' => OperationStatus::REJECTED]);
            $transfer->update(['operation_status' => OperationStatus::REJECTED]);

            $this->writeHistory(
                $operation,
                OperationStatus::PROJECT_HEAD_APPROVAL,
                OperationStatus::REJECTED,
                $actor->id,
                $user,
                $reason,
            );

            $operation->update(['operation_status' => OperationStatus::CREATED]);
            $transfer->update(['operation_status' => OperationStatus::CREATED]);

            $this->writeHistory(
                $operation,
                OperationStatus::REJECTED,
                OperationStatus::CREATED,
                $actor->id,
                $user,
                null,
            );

            return $transfer->fresh()->load(['sender.counterparty.user', 'receiver.counterparty.user']);
        });
    }

    public function resetApprovalByEmployee(
        Project $project,
        TransferOperation $transfer,
        ProjectParticipant $actor,
        User $user,
    ): TransferOperation {
        $this->assertSameProject($project, $transfer);
        $this->assertEmployeeInitiator($transfer, $actor);

        if ($transfer->operation_status !== OperationStatus::PROJECT_HEAD_APPROVAL) {
            throw ValidationException::withMessages([
                'status' => ['Сброс недоступен для текущего статуса.'],
            ]);
        }

        if ($transfer->wallets_applied_at !== null) {
            throw ValidationException::withMessages([
                'transfer' => ['Сброс невозможен: дельты уже применены.'],
            ]);
        }

        return DB::transaction(function () use ($transfer, $actor, $user) {
            $operation = $this->lockOperation($transfer);

            $operation->update(['operation_status' => OperationStatus::CREATED]);
            $transfer->update(['operation_status' => OperationStatus::CREATED]);

            $this->writeHistory(
                $operation,
                OperationStatus::PROJECT_HEAD_APPROVAL,
                OperationStatus::CREATED,
                $actor->id,
                $user,
                null,
            );

            return $transfer->fresh()->load(['sender.counterparty.user', 'receiver.counterparty.user']);
        });
    }

    public function submitForApprovalByEmployee(
        Project $project,
        TransferOperation $transfer,
        ProjectParticipant $actor,
        User $user,
    ): TransferOperation {
        $this->assertSameProject($project, $transfer);
        $this->assertEmployeeInitiator($transfer, $actor);

        if ($transfer->operation_status !== OperationStatus::CREATED) {
            throw ValidationException::withMessages([
                'status' => ['Отправка на согласование доступна только для статуса CREATED.'],
            ]);
        }

        if ($transfer->wallets_applied_at !== null) {
            throw ValidationException::withMessages([
                'transfer' => ['Невозможно отправить на согласование: дельты уже применены.'],
            ]);
        }

        return DB::transaction(function () use ($transfer, $actor, $user) {
            $operation = $this->lockOperation($transfer);

            $operation->update(['operation_status' => OperationStatus::PROJECT_HEAD_APPROVAL]);
            $transfer->update(['operation_status' => OperationStatus::PROJECT_HEAD_APPROVAL]);

            $this->writeHistory(
                $operation,
                OperationStatus::CREATED,
                OperationStatus::PROJECT_HEAD_APPROVAL,
                $actor->id,
                $user,
                null,
            );

            return $transfer->fresh()->load(['sender.counterparty.user', 'receiver.counterparty.user']);
        });
    }

    public function completeImmediateByHeadOrPartner(
        Project $project,
        TransferOperation $transfer,
        ProjectParticipant $actor,
        User $user,
    ): TransferOperation {
        $this->assertSameProject($project, $transfer);
        $this->assertHeadOrPartnerInitiator($transfer, $actor);

        if ($transfer->operation_status !== OperationStatus::CREATED) {
            throw ValidationException::withMessages([
                'status' => ['Завершение доступно только для статуса CREATED.'],
            ]);
        }

        if ($transfer->wallets_applied_at !== null) {
            throw ValidationException::withMessages([
                'transfer' => ['Операция уже проведена.'],
            ]);
        }

        return DB::transaction(function () use ($transfer, $actor, $user) {
            $operation = $this->lockOperation($transfer);
            [$senderW, $receiverW] = $this->lockTransferWallets($transfer);

            $this->balanceService->applyTransfer(
                $senderW,
                $receiverW,
                $transfer->transfer_target_type,
                (string) $transfer->amount,
            );

            $utcNow = Carbon::now('UTC');

            $transfer->update([
                'operation_status'    => OperationStatus::COMPLETED,
                'wallets_applied_at'  => $utcNow,
                'wallets_reverted_at' => null,
            ]);

            $operation->update(['operation_status' => OperationStatus::COMPLETED]);

            $this->writeHistory(
                $operation,
                OperationStatus::CREATED,
                OperationStatus::COMPLETED,
                $actor->id,
                $user,
                null,
            );

            return $transfer->fresh()->load(['sender.counterparty.user', 'receiver.counterparty.user']);
        });
    }

    public function returnToCreatedFromWaitingByEmployee(
        Project $project,
        TransferOperation $transfer,
        ProjectParticipant $actor,
        User $user,
        string $comment,
    ): TransferOperation {
        $this->assertSameProject($project, $transfer);
        $this->assertEmployeeInitiator($transfer, $actor);

        if ($transfer->operation_status !== OperationStatus::WAITING_24_HOURS) {
            throw ValidationException::withMessages([
                'status' => ['Возврат сотрудником доступен только в WAITING_24_HOURS.'],
            ]);
        }

        if ($transfer->wallets_applied_at === null) {
            throw ValidationException::withMessages([
                'transfer' => ['Дельты не применены — откат невозможен.'],
            ]);
        }

        return DB::transaction(function () use ($transfer, $actor, $user, $comment) {
            $operation = $this->lockOperation($transfer);
            $this->revertTransferWallets($transfer);

            $utcNow = Carbon::now('UTC');

            $transfer->update([
                'operation_status'           => OperationStatus::CREATED,
                'wallets_applied_at'         => null,
                'wallets_reverted_at'        => $utcNow,
                'waiting_period_started_at'  => null,
            ]);

            $operation->update(['operation_status' => OperationStatus::CREATED]);

            $this->writeHistory(
                $operation,
                OperationStatus::WAITING_24_HOURS,
                OperationStatus::CREATED,
                $actor->id,
                $user,
                $comment,
            );

            return $transfer->fresh()->load(['sender.counterparty.user', 'receiver.counterparty.user']);
        });
    }

    public function returnToProjectHeadApprovalFromWaiting(
        Project $project,
        TransferOperation $transfer,
        ProjectParticipant $actor,
        User $user,
    ): TransferOperation {
        $this->assertSameProject($project, $transfer);
        $this->assertProjectHeadActor($actor);

        if ($transfer->operation_status !== OperationStatus::WAITING_24_HOURS) {
            throw ValidationException::withMessages([
                'status' => ['Действие доступно только в WAITING_24_HOURS.'],
            ]);
        }

        if ($transfer->wallets_applied_at === null) {
            throw ValidationException::withMessages([
                'transfer' => ['Дельты не применены — откат невозможен.'],
            ]);
        }

        return DB::transaction(function () use ($transfer, $actor, $user) {
            $operation = $this->lockOperation($transfer);
            $this->revertTransferWallets($transfer);

            $utcNow = Carbon::now('UTC');

            $transfer->update([
                'operation_status'           => OperationStatus::PROJECT_HEAD_APPROVAL,
                'wallets_applied_at'         => null,
                'wallets_reverted_at'        => $utcNow,
                'waiting_period_started_at'  => null,
            ]);

            $operation->update(['operation_status' => OperationStatus::PROJECT_HEAD_APPROVAL]);

            $this->writeHistory(
                $operation,
                OperationStatus::WAITING_24_HOURS,
                OperationStatus::PROJECT_HEAD_APPROVAL,
                $actor->id,
                $user,
                null,
            );

            return $transfer->fresh()->load(['sender.counterparty.user', 'receiver.counterparty.user']);
        });
    }

    public function completeWaitingByProjectHead(
        Project $project,
        TransferOperation $transfer,
        ProjectParticipant $actor,
        User $user,
    ): TransferOperation {
        $this->assertSameProject($project, $transfer);
        $this->assertProjectHeadActor($actor);

        if ($transfer->operation_status !== OperationStatus::WAITING_24_HOURS) {
            throw ValidationException::withMessages([
                'status' => ['Операция не в периоде ожидания 24 часов.'],
            ]);
        }

        return DB::transaction(function () use ($transfer, $actor, $user) {
            $operation = $this->lockOperation($transfer);

            $transfer->update(['operation_status' => OperationStatus::COMPLETED]);
            $operation->update(['operation_status' => OperationStatus::COMPLETED]);

            $this->writeHistory(
                $operation,
                OperationStatus::WAITING_24_HOURS,
                OperationStatus::COMPLETED,
                $actor->id,
                $user,
                null,
            );

            return $transfer->fresh()->load(['sender.counterparty.user', 'receiver.counterparty.user']);
        });
    }

    public function rollbackCompletedHeadOrPartner(
        Project $project,
        TransferOperation $transfer,
        ProjectParticipant $actor,
        User $user,
        string $comment,
    ): TransferOperation {
        $this->assertSameProject($project, $transfer);

        $transfer->loadMissing('initiator');

        if ($transfer->operation_status !== OperationStatus::COMPLETED) {
            throw ValidationException::withMessages([
                'status' => ['Откат доступен только для завершённой операции.'],
            ]);
        }

        $initiator = $transfer->initiator;
        $role = $initiator->project_role_code;

        if (! in_array($role, [ProjectRoleCode::PROJECT_HEAD->value, ProjectRoleCode::PARTNER->value], true)) {
            throw ValidationException::withMessages([
                'transfer' => ['Этот сценарий отката применим только к операциям руководителя проекта или партнёра.'],
            ]);
        }

        if ($role === ProjectRoleCode::PROJECT_HEAD->value) {
            if ((int) $actor->id !== (int) $initiator->id) {
                throw ValidationException::withMessages([
                    'actor' => ['Откат может выполнить только инициатор — руководитель проекта.'],
                ]);
            }
        } else {
            $allowed = (int) $actor->id === (int) $initiator->id
                || $actor->project_role_code === ProjectRoleCode::PROJECT_HEAD->value;
            if (! $allowed) {
                throw ValidationException::withMessages([
                    'actor' => ['Откат может выполнить инициатор-партнёр или руководитель проекта.'],
                ]);
            }
        }

        if ($transfer->wallets_applied_at === null) {
            throw ValidationException::withMessages([
                'transfer' => ['Дельты не зафиксированы — откат невозможен.'],
            ]);
        }

        return DB::transaction(function () use ($transfer, $actor, $user, $comment) {
            $operation = $this->lockOperation($transfer);
            $this->revertTransferWallets($transfer);

            $utcNow = Carbon::now('UTC');

            $transfer->update([
                'operation_status'    => OperationStatus::CREATED,
                'wallets_applied_at'  => null,
                'wallets_reverted_at' => $utcNow,
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

            return $transfer->fresh()->load(['sender.counterparty.user', 'receiver.counterparty.user']);
        });
    }

    public function returnCompletedEmployeeToProjectHeadApproval(
        Project $project,
        TransferOperation $transfer,
        ProjectParticipant $actor,
        User $user,
        string $comment,
    ): TransferOperation {
        $this->assertSameProject($project, $transfer);
        $this->assertProjectHeadActor($actor);

        $transfer->loadMissing('initiator');

        if ($transfer->operation_status !== OperationStatus::COMPLETED) {
            throw ValidationException::withMessages([
                'status' => ['Действие доступно только для COMPLETED.'],
            ]);
        }

        if ($transfer->initiator->project_role_code !== ProjectRoleCode::EMPLOYEE->value) {
            throw ValidationException::withMessages([
                'transfer' => ['Сценарий только для операций, созданных сотрудником.'],
            ]);
        }

        if ($transfer->wallets_applied_at === null) {
            throw ValidationException::withMessages([
                'transfer' => ['Дельты не зафиксированы — откат невозможен.'],
            ]);
        }

        return DB::transaction(function () use ($transfer, $actor, $user, $comment) {
            $operation = $this->lockOperation($transfer);
            $this->revertTransferWallets($transfer);

            $utcNow = Carbon::now('UTC');

            $transfer->update([
                'operation_status'           => OperationStatus::PROJECT_HEAD_APPROVAL,
                'wallets_applied_at'         => null,
                'wallets_reverted_at'        => $utcNow,
                'waiting_period_started_at'  => null,
            ]);

            $operation->update(['operation_status' => OperationStatus::PROJECT_HEAD_APPROVAL]);

            $this->writeHistory(
                $operation,
                OperationStatus::COMPLETED,
                OperationStatus::PROJECT_HEAD_APPROVAL,
                $actor->id,
                $user,
                $comment,
            );

            return $transfer->fresh()->load(['sender.counterparty.user', 'receiver.counterparty.user']);
        });
    }

    private function assertSameProject(Project $project, TransferOperation $transfer): void
    {
        if ((int) $transfer->project_id !== (int) $project->id) {
            throw ValidationException::withMessages([
                'project' => ['Операция принадлежит другому проекту.'],
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

    private function assertEmployeeInitiator(TransferOperation $transfer, ProjectParticipant $actor): void
    {
        if ((int) $transfer->initiator_project_participant_id !== (int) $actor->id) {
            throw ValidationException::withMessages([
                'actor' => ['Действие доступно только инициатору операции.'],
            ]);
        }

        if ($actor->project_role_code !== ProjectRoleCode::EMPLOYEE->value) {
            throw ValidationException::withMessages([
                'actor' => ['Инициатор должен быть сотрудником.'],
            ]);
        }
    }

    private function assertHeadOrPartnerInitiator(TransferOperation $transfer, ProjectParticipant $actor): void
    {
        if ((int) $transfer->initiator_project_participant_id !== (int) $actor->id) {
            throw ValidationException::withMessages([
                'actor' => ['Действие доступно только инициатору операции.'],
            ]);
        }

        if (! in_array($actor->project_role_code, [
            ProjectRoleCode::PROJECT_HEAD->value,
            ProjectRoleCode::PARTNER->value,
        ], true)) {
            throw ValidationException::withMessages([
                'actor' => ['Инициатор должен быть руководителем проекта или партнёром.'],
            ]);
        }
    }

    private function lockOperation(TransferOperation $transfer): Operation
    {
        /** @var Operation $op */
        $op = Operation::query()->whereKey($transfer->operation_id)->lockForUpdate()->firstOrFail();

        return $op;
    }

    /**
     * @return array{0:\App\Modules\Projects\Models\ProjectParticipantWallet,1:\App\Modules\Projects\Models\ProjectParticipantWallet}
     */
    private function lockTransferWallets(TransferOperation $transfer): array
    {
        $sender = ProjectParticipant::query()
            ->whereKey($transfer->sender_project_participant_id)
            ->lockForUpdate()
            ->firstOrFail();

        $receiver = ProjectParticipant::query()
            ->whereKey($transfer->receiver_project_participant_id)
            ->lockForUpdate()
            ->firstOrFail();

        $senderWallet = $this->walletService->ensureWallet($sender);
        $receiverWallet = $this->walletService->ensureWallet($receiver);

        $senderWallet = $senderWallet->newQuery()
            ->whereKey($senderWallet->id)
            ->lockForUpdate()
            ->firstOrFail();

        $receiverWallet = $receiverWallet->newQuery()
            ->whereKey($receiverWallet->id)
            ->lockForUpdate()
            ->firstOrFail();

        return [$senderWallet, $receiverWallet];
    }

    private function revertTransferWallets(TransferOperation $transfer): void
    {
        [$senderW, $receiverW] = $this->lockTransferWallets($transfer);

        $this->balanceService->revertTransfer(
            $senderW,
            $receiverW,
            $transfer->transfer_target_type,
            (string) $transfer->amount,
        );
    }

    private function writeHistory(
        Operation $operation,
        ?OperationStatus $from,
        OperationStatus $to,
        ?int $changedByParticipantId,
        ?User $user,
        ?string $comment,
    ): void {
        OperationStatusHistory::query()->create([
            'operation_id'                      => $operation->id,
            'from_status'                     => $from,
            'to_status'                       => $to,
            'changed_by_project_participant_id' => $changedByParticipantId,
            'author_user_id'                  => $user?->id,
            'author_full_name'                => $user?->name,
            'comment'                         => $comment,
        ]);
    }

    /**
     * Авто завершение после 24ч в UTC от waiting_period_started_at (ТЗ-05.2 §19).
     *
     * @return bool true если статус изменён
     */
    public function autoCompleteWaitingIfDue(TransferOperation $transfer): bool
    {
        if ($transfer->operation_status !== OperationStatus::WAITING_24_HOURS) {
            return false;
        }

        if ($transfer->waiting_period_started_at === null || $transfer->wallets_applied_at === null) {
            return false;
        }

        $startUtc = Carbon::parse($transfer->waiting_period_started_at)->timezone('UTC');
        if (Carbon::now('UTC')->lessThan($startUtc->copy()->addHours(24))) {
            return false;
        }

        return DB::transaction(function () use ($transfer) {
            /** @var TransferOperation $fresh */
            $fresh = TransferOperation::query()->whereKey($transfer->id)->lockForUpdate()->firstOrFail();

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
            );

            return true;
        });
    }
}