<?php

namespace App\Modules\Operations\Services;

use App\Models\User;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Enums\OperationType;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Models\Operation;
use App\Modules\Operations\Models\OperationStatusHistory;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class IncomeService
{
    public function __construct(
        private readonly IncomeBalanceService $balanceService,
        private readonly IncomeProjectParticipantsResolver $roleResolver,
    ) {}

    /**
     * ТЗ-06: создание поступления HEAD/PARTNER первого порядка → сразу CUSTOMER_APPROVAL с apply дельт.
     *
     * @throws ValidationException
     */
    public function create(
        Project $project,
        ProjectParticipant $initiator,
        string $amount,
        ?string $comment,
        ?User $initiatorUser,
    ): IncomeOperation {
        $this->assertInitiatorCanCreateIncome($initiator);

        [$head, $customer] = $this->roleResolver->resolveHeadAndCustomer($project);

        return DB::transaction(function () use (
            $project,
            $initiator,
            $amount,
            $comment,
            $head,
            $customer,
            $initiatorUser,
        ): IncomeOperation {
            $utcNow = Carbon::now('UTC');

            $operation = Operation::query()->create([
                'project_id'                       => $project->id,
                'initiator_project_participant_id' => $initiator->id,
                'operation_type'                   => OperationType::INCOME,
                'operation_status'                 => OperationStatus::CREATED,
            ]);

            $this->appendHistory(
                $operation,
                null,
                OperationStatus::CREATED,
                $initiator->id,
                $initiatorUser,
                null,
            );

            $operation->update(['operation_status' => OperationStatus::CUSTOMER_APPROVAL]);

            $this->appendHistory(
                $operation,
                OperationStatus::CREATED,
                OperationStatus::CUSTOMER_APPROVAL,
                $initiator->id,
                $initiatorUser,
                null,
            );

            $income = IncomeOperation::query()->create([
                'operation_id'                       => $operation->id,
                'project_id'                         => $project->id,
                'initiator_project_participant_id'   => $initiator->id,
                'project_head_project_participant_id'=> $head->id,
                'customer_project_participant_id'    => $customer->id,
                'amount'                             => $amount,
                'comment'                            => $comment,
                'operation_status'                   => OperationStatus::CUSTOMER_APPROVAL,
                'wallets_applied_at'                 => null,
                'wallets_reverted_at'                => null,
                'waiting_period_started_at'          => null,
            ]);

            $this->balanceService->applyIncomeDeltas($income);

            $income->update([
                'wallets_applied_at' => $utcNow,
                'wallets_reverted_at' => null,
            ]);

            $operation->refresh();

            return $income->fresh()->load([
                'initiator.counterparty.user',
                'projectHead.counterparty.user',
                'customer.counterparty.user',
                'project',
            ]);
        });
    }

    /**
     * @throws ValidationException
     */
    private function assertInitiatorCanCreateIncome(ProjectParticipant $initiator): void
    {
        if (strtolower((string) $initiator->level) !== 'first') {
            throw ValidationException::withMessages([
                'initiator' => ['Создавать поступление может только участник первого порядка.'],
            ]);
        }

        $allowed = [ProjectRoleCode::PROJECT_HEAD->value, ProjectRoleCode::PARTNER->value];

        if (! in_array($initiator->project_role_code, $allowed, true)) {
            throw ValidationException::withMessages([
                'initiator' => ['Поступление могут создавать только руководитель проекта или партнёр.'],
            ]);
        }
    }

    private function appendHistory(
        Operation $operation,
        ?OperationStatus $from,
        OperationStatus $to,
        ?int $changedByParticipantId,
        ?User $user,
        ?string $comment,
    ): void {
        OperationStatusHistory::query()->create([
            'operation_id'                      => $operation->id,
            'from_status'                       => $from,
            'to_status'                         => $to,
            'changed_by_project_participant_id' => $changedByParticipantId,
            'author_user_id'                    => $user?->id,
            'author_full_name'                  => $user?->name,
            'comment'                           => $comment,
        ]);
    }
}
