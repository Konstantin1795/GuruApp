<?php

namespace App\Modules\Operations\Services;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\TransferTargetType;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\WalletFactoryService;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * ТЗ-05.2 v3: разрешение получателя и проверки уровня/ролей в рамках project_id.
 */
final class TransferParticipantResolver
{
    public function __construct(
        private readonly WalletFactoryService $walletFactory,
    ) {}

    /**
     * @throws ValidationException
     */
    public function resolveAccountableReceiver(
        Project $project,
        ProjectParticipant $initiator,
        int $receiverProjectParticipantId,
    ): ProjectParticipant {
        $receiver = ProjectParticipant::query()
            ->where('id', $receiverProjectParticipantId)
            ->where('project_id', $project->id)
            ->where('is_active', true)
            ->first();

        if (! $receiver) {
            throw ValidationException::withMessages([
                'receiver_project_participant_id' => ['Получатель должен быть участником этого проекта.'],
            ]);
        }

        if (strtolower((string) $receiver->level) !== 'first') {
            throw ValidationException::withMessages([
                'receiver_project_participant_id' => ['Для перевода на подотчётный баланс получатель должен быть участником первого порядка.'],
            ]);
        }

        $allowedReceiverRoles = [
            ProjectRoleCode::PROJECT_HEAD->value,
            ProjectRoleCode::PARTNER->value,
            ProjectRoleCode::EMPLOYEE->value,
        ];

        if (! in_array($receiver->project_role_code, $allowedReceiverRoles, true)) {
            throw ValidationException::withMessages([
                'receiver_project_participant_id' => ['Эта роль недоступна как получатель подотчётного перевода.'],
            ]);
        }

        if ((int) $receiver->id === (int) $initiator->id) {
            throw ValidationException::withMessages([
                'receiver_project_participant_id' => ['Нельзя перевести средства самому себе.'],
            ]);
        }

        return $receiver;
    }

    /**
     * @throws ValidationException
     */
    public function resolvePersonalReceiver(
        Project $project,
        int $companyId,
        ProjectParticipant $initiator,
        int $receiverCounterpartyId,
    ): ProjectParticipant {
        $counterparty = Counterparty::query()
            ->where('id', $receiverCounterpartyId)
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->first();

        if (! $counterparty) {
            throw ValidationException::withMessages([
                'receiver_counterparty_id' => ['Контрагент не найден в этой компании.'],
            ]);
        }

        $allowed = [
            CompanyRoleCode::OWNER->value,
            CompanyRoleCode::PARTNER->value,
            CompanyRoleCode::EMPLOYEE->value,
            CompanyRoleCode::SUPPLIER->value,
            CompanyRoleCode::CONTRACTOR->value,
            CompanyRoleCode::CUSTOMER->value,
        ];

        if (! in_array($counterparty->company_role_code, $allowed, true)) {
            throw ValidationException::withMessages([
                'receiver_counterparty_id' => ['Эта роль контрагента недоступна для расчётного перевода.'],
            ]);
        }

        $projectRole = $this->mapCompanyRoleToProjectRole($counterparty->company_role_code);

        $existing = ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('counterparty_id', $counterparty->id)
            ->first();

        if ($existing) {
            return $existing;
        }

        return DB::transaction(function () use ($project, $counterparty, $projectRole) {
            $participant = ProjectParticipant::query()->create([
                'project_id'        => $project->id,
                'counterparty_id'   => $counterparty->id,
                'project_role_code' => $projectRole,
                'level'             => 'second',
                'is_active'         => true,
            ]);

            $this->walletFactory->createForParticipant($participant);

            return $participant;
        });
    }

    /**
     * @throws ValidationException
     */
    public function assertInitiatorCanCreateTransfer(ProjectParticipant $initiator): void
    {
        if (strtolower((string) $initiator->level) !== 'first') {
            throw ValidationException::withMessages([
                'initiator' => ['Создавать перевод может только участник проекта первого порядка.'],
            ]);
        }

        $allowed = [
            ProjectRoleCode::PROJECT_HEAD->value,
            ProjectRoleCode::PARTNER->value,
            ProjectRoleCode::EMPLOYEE->value,
        ];

        if (! in_array($initiator->project_role_code, $allowed, true)) {
            throw ValidationException::withMessages([
                'initiator' => ['Ваша роль не может создавать операцию «Перевод».'],
            ]);
        }
    }

    /**
     * @throws ValidationException
     */
    private function mapCompanyRoleToProjectRole(string $companyRoleCode): string
    {
        return match ($companyRoleCode) {
            CompanyRoleCode::OWNER->value => ProjectRoleCode::PARTNER->value,
            CompanyRoleCode::PARTNER->value => ProjectRoleCode::PARTNER->value,
            CompanyRoleCode::EMPLOYEE->value => ProjectRoleCode::EMPLOYEE->value,
            CompanyRoleCode::SUPPLIER->value => ProjectRoleCode::SUPPLIER->value,
            CompanyRoleCode::CONTRACTOR->value => ProjectRoleCode::CONTRACTOR->value,
            CompanyRoleCode::CUSTOMER->value => ProjectRoleCode::CUSTOMER->value,
            default => throw ValidationException::withMessages([
                'receiver_counterparty_id' => ['Роль контрагента не поддерживается для автодобавления в проект.'],
            ]),
        };
    }
}
