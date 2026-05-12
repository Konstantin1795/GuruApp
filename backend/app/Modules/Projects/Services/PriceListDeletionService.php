<?php

namespace App\Modules\Projects\Services;

use App\Modules\Projects\Models\PriceList;
use App\Modules\Projects\Models\PriceListGroup;
use App\Modules\Projects\Models\PriceListPosition;
use App\Modules\Projects\Models\ProjectPriceList;
use Illuminate\Support\Facades\DB;

final class PriceListDeletionService
{
    public function __construct(
        private readonly PriceListReportUsageChecker $reportUsage,
    ) {}

    public function countProjectsUsingPriceList(int $priceListId): int
    {
        return (int) ProjectPriceList::query()
            ->where('price_list_id', $priceListId)
            ->distinct('project_id')
            ->count('project_id');
    }

    /**
     * @return array{deleted_mode: string, detached_projects_count: int}
     */
    public function deletePriceList(PriceList $priceList): array
    {
        $projectsCount = $this->countProjectsUsingPriceList((int) $priceList->id);

        return DB::transaction(function () use ($priceList, $projectsCount): array {
            ProjectPriceList::query()
                ->where('price_list_id', (int) $priceList->id)
                ->delete();

            if ($this->reportUsage->priceListUsedInReports((int) $priceList->id)) {
                $this->softDeletePriceListTree($priceList);

                return [
                    'deleted_mode' => 'soft',
                    'detached_projects_count' => $projectsCount,
                ];
            }

            $priceList->forceDelete();

            return [
                'deleted_mode' => 'hard',
                'detached_projects_count' => $projectsCount,
            ];
        });
    }

    public function deleteGroup(PriceListGroup $group): void
    {
        DB::transaction(function () use ($group): void {
            $group->positions()->orderBy('id')->get()->each(function (PriceListPosition $position): void {
                $this->deletePosition($position);
            });

            if ($group->positions()->onlyTrashed()->exists()) {
                $group->is_active = false;
                $group->save();
                $group->delete();

                return;
            }

            $group->forceDelete();
        });
    }

    public function deletePosition(PriceListPosition $position): void
    {
        if ($this->reportUsage->priceListPositionUsedInReports((int) $position->id)) {
            $position->is_active = false;
            $position->save();
            $position->delete();

            return;
        }

        $position->forceDelete();
    }

    private function softDeletePriceListTree(PriceList $priceList): void
    {
        $priceList->groups()->orderBy('id')->each(function (PriceListGroup $group): void {
            $group->positions()->orderBy('id')->each(function (PriceListPosition $position): void {
                $position->is_active = false;
                $position->save();
                $position->delete();
            });
            $group->is_active = false;
            $group->save();
            $group->delete();
        });

        $priceList->is_active = false;
        $priceList->save();
        $priceList->delete();
    }
}
