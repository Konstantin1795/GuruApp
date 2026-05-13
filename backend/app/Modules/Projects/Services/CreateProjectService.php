<?php

declare(strict_types=1);

namespace App\Modules\Projects\Services;

use App\Models\User;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Создание проекта в company-workspace (OWNER | PARTNER компании как создатель).
 *
 * REPORT не должен встраивать сюда проведение дельт: операция «Отчёт» — отдельный lifecycle
 * и отдельные сервисы баланса (см. черновик `docs/10_operations/13_OPERATION_REPORT_DRAFT.md`).
 */
final class CreateProjectService
{
    public function __construct(
        private readonly WalletFactoryService $walletFactory,
    ) {}

    /**
     * @param  array{name: string, is_active?: bool, customer_counterparty_id?: int|null}  $payload
     *         validated payload from {@see \App\Modules\Projects\Http\Requests\CreateProjectRequest}
     */
    public function createFromCompanyWorkspace(User $user, int $companyId, array $payload): Project
    {
        $customerCounterpartyId = isset($payload['customer_counterparty_id'])
            ? (int) $payload['customer_counterparty_id']
            : null;

        $creatorCounterpartyId = (int) Counterparty::query()
            ->where('company_id', $companyId)
            ->where('user_id', (int) $user->id)
            ->where('is_active', true)
            ->whereIn('company_role_code', [
                CompanyRoleCode::OWNER->value,
                CompanyRoleCode::PARTNER->value,
            ])
            ->value('id');

        if (! $creatorCounterpartyId) {
            abort(403, 'Forbidden.');
        }

        if ($customerCounterpartyId) {
            $belongs = Counterparty::query()
                ->where('id', $customerCounterpartyId)
                ->where('company_id', $companyId)
                ->exists();

            if (! $belongs) {
                throw ValidationException::withMessages([
                    'customer_counterparty_id' => ['Counterparty must belong to the same company.'],
                ]);
            }
        }

        return DB::transaction(function () use (
            $companyId,
            $payload,
            $creatorCounterpartyId,
            $customerCounterpartyId,
        ): Project {
            $project = Project::query()->create([
                'company_id'       => $companyId,
                'name'             => (string) $payload['name'],
                'progress_percent' => 0,
                'is_active'        => array_key_exists('is_active', $payload) ? (bool) $payload['is_active'] : true,
            ]);

            $head = ProjectParticipant::query()->create([
                'project_id'        => $project->id,
                'counterparty_id'   => $creatorCounterpartyId,
                'project_role_code' => ProjectRoleCode::PROJECT_HEAD->value,
                'level'             => 'first',
                'is_active'         => true,
            ]);
            $this->walletFactory->createForParticipant($head);

            if ($customerCounterpartyId && $customerCounterpartyId !== $creatorCounterpartyId) {
                // Заказчик, выбранный при создании проекта — участник первого порядка (как PROJECT_HEAD).
                // level = second — для участников, появляющихся через операции, не для CUSTOMER из create.
                $customer = ProjectParticipant::query()->create([
                    'project_id'        => $project->id,
                    'counterparty_id'   => $customerCounterpartyId,
                    'project_role_code' => ProjectRoleCode::CUSTOMER->value,
                    'level'             => 'first',
                    'is_active'         => true,
                ]);
                $this->walletFactory->createForParticipant($customer);
            }

            return $project;
        });
    }
}
