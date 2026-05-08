<?php

namespace App\Modules\Companies\Http\Controllers\CompanyWorkspace;

use App\Modules\Companies\Http\Requests\CreateCompanyRequest;
use App\Modules\Companies\Http\Resources\CompanyResource;
use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use App\Support\Http\ApiResponse;
use Illuminate\Support\Facades\DB;

final class CreateCompanyController
{
    public function __invoke(CreateCompanyRequest $request)
    {
        $user = $request->user();
        $data = $request->validated();

        $result = DB::transaction(function () use ($user, $data) {
            $company = Company::query()->create([
                'name' => $data['name'],
                'created_by_user_id' => $user->id,
                'is_active' => true,
            ]);

            Counterparty::query()->create([
                'company_id' => $company->id,
                'user_id' => $user->id,
                'company_role_code' => CompanyRoleCode::OWNER->value,
                'is_active' => true,
            ]);

            return $company;
        });

        return ApiResponse::ok([
            'company' => (new CompanyResource($result))->resolve(),
            'role' => CompanyRoleCode::OWNER->value,
        ], status: 201);
    }
}

