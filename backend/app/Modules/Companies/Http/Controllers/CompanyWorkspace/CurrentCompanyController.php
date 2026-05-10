<?php

namespace App\Modules\Companies\Http\Controllers\CompanyWorkspace;

use App\Modules\Companies\Http\Resources\CompanyResource;
use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class CurrentCompanyController
{
    public function __invoke(Request $request, int $companyId)
    {
        $company = Company::query()->findOrFail($companyId);

        $myCompanyRole = Counterparty::query()
            ->where('company_id', $companyId)
            ->where('user_id', (int) $request->user()->id)
            ->where('is_active', true)
            ->value('company_role_code');

        return ApiResponse::ok([
            'company' => (new CompanyResource($company))->resolve(),
            'my_company_role' => $myCompanyRole !== null ? (string) $myCompanyRole : null,
        ]);
    }
}

