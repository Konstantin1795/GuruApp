<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Http\Requests\CreateProjectRequest;
use App\Modules\Projects\Http\Resources\ProjectResource;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\WalletFactoryService;
use App\Support\Http\ApiResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class CreateProjectController
{
    public function __construct(private readonly WalletFactoryService $walletFactory) {}

    public function __invoke(CreateProjectRequest $request, int $companyId)
    {
        $user = $request->user();
        if (! $user) {
            abort(401, 'Unauthenticated.');
        }

        $payload = $request->validated();
        $customerCounterpartyId = isset($payload['customer_counterparty_id'])
            ? (int) $payload['customer_counterparty_id']
            : null;

        $creatorCounterpartyId = (int) Counterparty::query()
            ->where('company_id', $companyId)
            ->where('user_id', (int) $user->id)
            ->where('is_active', true)
            ->where('company_role_code', CompanyRoleCode::OWNER->value)
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

        $project = DB::transaction(function () use (
            $companyId,
            $payload,
            $creatorCounterpartyId,
            $customerCounterpartyId,
        ) {
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
                $customer = ProjectParticipant::query()->create([
                    'project_id'        => $project->id,
                    'counterparty_id'   => $customerCounterpartyId,
                    'project_role_code' => ProjectRoleCode::CUSTOMER->value,
                    'level'             => 'second',
                    'is_active'         => true,
                ]);
                $this->walletFactory->createForParticipant($customer);
            }

            return $project;
        });

        return ApiResponse::ok([
            'project' => (new ProjectResource($project))->resolve(),
        ]);
    }
}

