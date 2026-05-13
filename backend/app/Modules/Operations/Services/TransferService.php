<?php

namespace App\Modules\Operations\Services;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Enums\OperationType;
use App\Modules\Operations\Enums\TransferTargetType;
use App\Modules\Operations\Models\Operation;
use App\Modules\Operations\Models\OperationStatusHistory;
use App\Modules\Operations\Models\TransferOperation;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\WalletService;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class TransferService
{
    public function __construct(
        private readonly TransferBalanceService $balanceService,
        private readonly WalletService $walletService,
        private readonly TransferParticipantResolver $participantResolver,
    ) {}

    /**
     * ТЗ-05.2 v3: создание перевода в рамках project_id.
     * PROJECT_HEAD / PARTNER: CREATED → COMPLETED, дельты сразу.
     * EMPLOYEE: CREATED → PROJECT_HEAD_APPROVAL (две записи истории), дельты не применяются.
     *
     * @throws ValidationException
     */
    public function create(
        Project $project,
        int $companyId,
        ProjectParticipant $initiator,
        TransferTargetType $targetType,
        string $amount,
        ?string $comment,
        ?int $receiverProjectParticipantId,
        ?int $receiverCounterpartyId,
    ): TransferOperation {
        $this->participantResolver->assertInitiatorCanCreateTransfer($initiator);

        $receiver = match ($targetType) {
            TransferTargetType::ACCOUNTABLE_BALANCE => $this->participantResolver->resolveAccountableReceiver(
                $project,
                $initiator,
                (int) $receiverProjectParticipantId,
            ),
            TransferTargetType::PERSONAL_BALANCE => $this->participantResolver->resolvePersonalReceiver(
                $project,
                $companyId,
                $initiator,
                (int) $receiverCounterpartyId,
            ),
        };

        $immediate = in_array($initiator->project_role_code, [
            ProjectRoleCode::PROJECT_HEAD->value,
            ProjectRoleCode::PARTNER->value,
        ], true);

        $finalStatus = $immediate ? OperationStatus::COMPLETED : OperationStatus::PROJECT_HEAD_APPROVAL;

        return DB::transaction(function () use (
            $project,
            $initiator,
            $receiver,
            $targetType,
            $amount,
            $comment,
            $immediate,
            $finalStatus,
            $receiverCounterpartyId,
        ) {
            $senderWallet = $this->walletService->ensureWallet($initiator);
            $receiverWallet = $this->walletService->ensureWallet($receiver);

            $senderWallet = $senderWallet->newQuery()
                ->whereKey($senderWallet->id)
                ->lockForUpdate()
                ->firstOrFail();
            $receiverWallet = $receiverWallet->newQuery()
                ->whereKey($receiverWallet->id)
                ->lockForUpdate()
                ->firstOrFail();

            /** @var Carbon $utcNow Явно UTC: дельты времени 24ч и audit в БД согласованы с ТЗ-05.2 §17 / §19. */
            $utcNow = Carbon::now('UTC');

            $operation = Operation::query()->create([
                'project_id'                       => $project->id,
                'initiator_project_participant_id' => $initiator->id,
                'operation_type'                   => OperationType::TRANSFER,
                'operation_status'                 => OperationStatus::CREATED,
            ]);

            $this->appendHistory(
                $operation,
                null,
                OperationStatus::CREATED,
                $initiator->id,
                null,
                null,
                null,
            );

            if ($finalStatus !== OperationStatus::CREATED) {
                $operation->update(['operation_status' => $finalStatus]);
                $this->appendHistory(
                    $operation,
                    OperationStatus::CREATED,
                    $finalStatus,
                    $initiator->id,
                    null,
                    null,
                    null,
                );
            }

            if ($immediate) {
                $this->balanceService->applyTransfer($senderWallet, $receiverWallet, $targetType, $amount);
            }

            $counterpartyId = $targetType === TransferTargetType::PERSONAL_BALANCE
                ? (int) $receiverCounterpartyId
                : null;

            $transfer = TransferOperation::query()->create([
                'operation_id'                       => $operation->id,
                'project_id'                         => $project->id,
                'initiator_project_participant_id'   => $initiator->id,
                'sender_project_participant_id'      => $initiator->id,
                'receiver_project_participant_id'    => $receiver->id,
                'receiver_counterparty_id'           => $counterpartyId,
                'transfer_target_type'               => $targetType,
                'amount'                             => $amount,
                'comment'                            => $comment,
                'operation_status'                   => $finalStatus,
                'wallets_applied_at'                 => $immediate ? $utcNow : null,
                'wallets_reverted_at'                => null,
                'waiting_period_started_at'          => null,
            ]);

            app(ReportOperationNumberService::class)->assignTransferNumber($transfer);

            $operation->refresh();

            return $transfer->load(['sender.counterparty.user', 'receiver.counterparty.user']);
        });
    }

    private function appendHistory(
        Operation $operation,
        ?OperationStatus $from,
        OperationStatus $to,
        ?int $changedByParticipantId,
        ?int $authorUserId,
        ?string $authorFullName,
        ?string $comment,
    ): void {
        OperationStatusHistory::query()->create([
            'operation_id'                      => $operation->id,
            'from_status'                     => $from,
            'to_status'                       => $to,
            'changed_by_project_participant_id' => $changedByParticipantId,
            'author_user_id'                  => $authorUserId,
            'author_full_name'                => $authorFullName,
            'comment'                         => $comment,
        ]);
    }
}

