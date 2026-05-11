<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Services\AggregatedOperationsHistoryService;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;

final class ListAggregatedOperationsHistoryController
{
    public function __invoke(
        Request $request,
        AggregatedOperationsHistoryService $history,
    ) {
        $p = Pagination::fromRequest($request);
        $userId = (int) $request->user()->id;

        $projectIds = ProjectParticipant::query()
            ->where('is_active', true)
            ->whereHas('counterparty', function ($q) use ($userId): void {
                $q->where('user_id', $userId)->where('is_active', true);
            })
            ->distinct()
            ->pluck('project_id');

        $projects = Project::query()->whereIn('id', $projectIds)->get();

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
