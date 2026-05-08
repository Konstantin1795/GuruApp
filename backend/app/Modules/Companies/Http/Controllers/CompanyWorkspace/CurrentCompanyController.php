<?php

namespace App\Modules\Companies\Http\Controllers\CompanyWorkspace;

use App\Modules\Companies\Http\Resources\CompanyResource;
use App\Modules\Companies\Models\Company;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class CurrentCompanyController
{
    public function __invoke(Request $request, int $companyId)
    {
        $company = Company::query()->findOrFail($companyId);

        return ApiResponse::ok([
            'company' => (new CompanyResource($company))->resolve(),
        ]);
    }
}

