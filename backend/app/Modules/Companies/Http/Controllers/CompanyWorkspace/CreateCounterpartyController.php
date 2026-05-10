<?php

namespace App\Modules\Companies\Http\Controllers\CompanyWorkspace;

use App\Models\User;
use App\Modules\Companies\Http\Requests\CreateCounterpartyRequest;
use App\Modules\Companies\Http\Resources\CounterpartyResource;
use App\Modules\Companies\Models\Counterparty;
use App\Support\Http\ApiResponse;
use Illuminate\Database\QueryException;
use Illuminate\Validation\ValidationException;

final class CreateCounterpartyController
{
    public function __invoke(CreateCounterpartyRequest $request, int $companyId)
    {
        $payload = $request->validated();

        if (! empty($payload['user_id']) && ! empty($payload['email'])) {
            throw ValidationException::withMessages([
                'user_id' => ['Provide either user_id or email, not both.'],
                'email' => ['Provide either email or user_id, not both.'],
            ]);
        }

        $userId = null;
        if (! empty($payload['user_id'])) {
            $userId = (int) $payload['user_id'];
        } elseif (! empty($payload['email'])) {
            $userId = (int) (User::query()->where('email', $payload['email'])->value('id') ?? 0);
            $userId = $userId > 0 ? $userId : null;
        }

        try {
            $counterparty = Counterparty::query()->create([
                'company_id' => $companyId,
                'user_id' => $userId,
                'full_name' => (string) $payload['full_name'],
                'email' => (string) $payload['email'],
                'company_role_code' => (string) $payload['company_role_code'],
                'is_active' => array_key_exists('is_active', $payload) ? (bool) $payload['is_active'] : true,
            ]);
        } catch (QueryException $e) {
            // Unique company_id+user_id violation
            if ((string) $e->getCode() === '23505') { // Postgres unique_violation
                throw ValidationException::withMessages([
                    'user_id' => ['Counterparty already exists for this user in this company.'],
                ]);
            }
            throw $e;
        }

        $counterparty->load('user');

        return ApiResponse::ok([
            'counterparty' => (new CounterpartyResource($counterparty))->resolve(),
        ]);
    }
}

