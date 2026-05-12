<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\UnitService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ListUnitsController
{
    public function __invoke(Request $request, UnitService $units, int $companyId)
    {
        return ApiResponse::ok([
            'units' => $units->toListPayloads(),
        ]);
    }
}
