<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\ProjectPriceListService;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ListAvailableProjectPriceListsController
{
    public function __invoke(
        Request $request,
        ProjectVisibilityService $visibility,
        PriceListAccessService $access,
        ProjectPriceListService $projectLists,
        int $companyId,
        int $projectId,
    ) {
        $project = $visibility->assertCanAccessCompanyProject(
            (int) $request->user()->id,
            $companyId,
            $projectId,
        );

        $access->assertCanManageProjectPriceListAttachments($request->user(), $companyId, $project);

        $rows = $projectLists->availablePriceLists($request->user(), $companyId, $project, $access);

        $items = $rows->map(function ($pl) use ($projectLists): array {
            $pl->loadMissing(['createdByCounterparty', 'createdByUser']);

            return [
                'id' => $pl->id,
                'name' => $pl->name,
                'creator_display_name' => $this->creatorName($pl),
            ];
        })->values()->all();

        return ApiResponse::ok([
            'price_lists' => $items,
        ]);
    }

    private function creatorName(\App\Modules\Projects\Models\PriceList $pl): string
    {
        $cp = $pl->createdByCounterparty;
        if ($cp !== null && trim((string) $cp->full_name) !== '') {
            return (string) $cp->full_name;
        }

        return (string) ($pl->createdByUser?->name ?? '');
    }
}
