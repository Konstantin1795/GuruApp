<?php

namespace App\Modules\Workspaces\Http\Controllers;

use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Projects\Services\PriceListAccessService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class CompanyWorkspaceContextController
{
    public function __invoke(Request $request, PriceListAccessService $priceListAccess, int $companyId)
    {
        $userId = (int) $request->user()->id;

        $company = Company::query()->findOrFail($companyId);

        $counterparty = Counterparty::query()
            ->where('company_id', $companyId)
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->firstOrFail();

        $priceFlags = $priceListAccess->companyLibraryFlags($request->user(), $companyId);

        return ApiResponse::ok([
            'active_company_id' => $company->id,
            'company_role' => $counterparty->company_role_code,
            'company' => [
                'id' => $company->id,
                'name' => $company->name,
            ],
            'price_lists' => $priceFlags,
        ]);
    }
}

