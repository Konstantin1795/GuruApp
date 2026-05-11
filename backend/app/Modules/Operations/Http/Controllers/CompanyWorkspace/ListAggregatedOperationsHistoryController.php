<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\CompanyWorkspace;

use App\Modules\Operations\Services\AggregatedOperationsHistoryService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListAggregatedOperationsHistoryController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $projectVisibility,
        AggregatedOperationsHistoryService $history,
        int $companyId,
    ) {
        $p = Pagination::fromRequest($request);
        $userId = (int) $request->user()->id;

        $projects = $projectVisibility
            ->queryForCompanyWorkspace($userId, $companyId)
            ->get();

        $result = $history->paginate($projects, $userId, $p['per_page'], $p['page']);

        $lastPage = max(1, (int) ceil($result['total'] / $p['per_page']));

        return ApiResponse::ok([
            'items' => $result['items'],
            'pagination' => [
                'page' => $p['page'],
                'per_page' => $p['per_page'],
                'total' => $result['total'],
                'last_page' => $lastPage,
            ],
        ]);
    }
}
