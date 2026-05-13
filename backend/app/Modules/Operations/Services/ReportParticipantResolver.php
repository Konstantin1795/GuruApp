<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\WalletFactoryService;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Участник проекта для основного получателя отчёта (ТЗ-10C): существующий или second-order + кошелёк.
 */
final class ReportParticipantResolver
{
    public function __construct(
        private readonly WalletFactoryService $walletFactory,
    ) {}

    /**
     * @throws ValidationException
     */
    public function resolveRecipientParticipant(
        Project $project,
        int $companyId,
        int $recipientCounterpartyId,
        int $projectCustomerCounterpartyId,
    ): ProjectParticipant {
        if ($recipientCounterpartyId === $projectCustomerCounterpartyId) {
            throw ValidationException::withMessages([
                'recipient_counterparty_id' => ['Получатель отчёта не может быть заказчиком проекта.'],
            ]);
        }

        $counterparty = Counterparty::query()
            ->where('id', $recipientCounterpartyId)
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->first();

        if (! $counterparty) {
            throw ValidationException::withMessages([
                'recipient_counterparty_id' => ['Контрагент не найден в этой компании.'],
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
                'recipient_counterparty_id' => ['Этот контрагент недоступен как получатель отчёта.'],
            ]);
        }

        $existing = ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('counterparty_id', $counterparty->id)
            ->where('is_active', true)
            ->first();

        if ($existing) {
            return $existing;
        }

        return DB::transaction(function () use ($project, $counterparty): ProjectParticipant {
            $participant = ProjectParticipant::query()->create([
                'project_id'        => $project->id,
                'counterparty_id'   => $counterparty->id,
                'project_role_code' => $this->mapCompanyRoleToProjectRole($counterparty->company_role_code),
                'level'             => 'second',
                'is_active'         => true,
            ]);
            $this->walletFactory->createForParticipant($participant);

            return $participant;
        });
    }

    public function findCustomerParticipant(Project $project): ?ProjectParticipant
    {
        return ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('project_role_code', ProjectRoleCode::CUSTOMER->value)
            ->where('is_active', true)
            ->first();
    }

    /**
     * @throws ValidationException
     */
    public function requireCustomerParticipant(Project $project): ProjectParticipant
    {
        $p = $this->findCustomerParticipant($project);
        if ($p === null) {
            throw ValidationException::withMessages([
                'project' => ['В проекте должен быть активный заказчик (CUSTOMER).'],
            ]);
        }

        return $p;
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
            default => throw ValidationException::withMessages([
                'recipient_counterparty_id' => ['Роль контрагента не поддерживается для автодобавления в проект.'],
            ]),
        };
    }
}
