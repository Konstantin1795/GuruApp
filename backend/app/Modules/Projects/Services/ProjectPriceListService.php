<?php

namespace App\Modules\Projects\Services;

use App\Models\User;
use App\Modules\Projects\Models\PriceList;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectPriceList;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

final class ProjectPriceListService
{
    /**
     * @return list<array<string, mixed>>
     */
    public function listAttached(Project $project): array
    {
        return ProjectPriceList::query()
            ->where('project_id', (int) $project->id)
            ->with(['priceList' => function ($q): void {
                $q->withTrashed()->with(['createdByCounterparty', 'createdByUser']);
            }])
            ->orderByDesc('id')
            ->get()
            ->map(function (ProjectPriceList $row): array {
                $pl = $row->priceList;

                return [
                    'id' => $row->id,
                    'price_list' => $pl !== null ? [
                        'id' => $pl->id,
                        'name' => $pl->name,
                        'is_active' => (bool) $pl->is_active,
                        'deleted_at' => $pl->deleted_at?->toIso8601String(),
                        'creator_display_name' => $this->creatorName($pl),
                    ] : null,
                ];
            })
            ->all();
    }

    /**
     * @return Collection<int, PriceList>
     */
    public function availablePriceLists(User $user, int $companyId, Project $project, PriceListAccessService $access): Collection
    {
        $attachedIds = ProjectPriceList::query()
            ->where('project_id', (int) $project->id)
            ->pluck('price_list_id')
            ->all();

        $q = PriceList::query()
            ->where('company_id', $companyId)
            ->visible();

        if ($attachedIds !== []) {
            $q->whereNotIn('id', $attachedIds);
        }

        $cp = $access->companyCounterparty((int) $user->id, $companyId);
        if ($cp !== null && ! $access->isOwner($cp)) {
            $q->where('created_by_counterparty_id', (int) $cp->id);
        }

        return $q->with(['createdByCounterparty', 'createdByUser'])
            ->orderByDesc('id')
            ->get();
    }

    /**
     * @param list<int> $priceListIds
     *
     * @return list<int> attached ids
     */
    public function attach(User $user, int $companyId, Project $project, array $priceListIds, PriceListAccessService $access): array
    {
        $priceListIds = array_values(array_unique(array_map('intval', $priceListIds)));
        if ($priceListIds === []) {
            abort(422, 'price_list_ids is required.');
        }

        return DB::transaction(function () use ($user, $companyId, $project, $priceListIds, $access): array {
            $attached = [];
            foreach ($priceListIds as $pid) {
                $list = PriceList::query()
                    ->where('company_id', $companyId)
                    ->visible()
                    ->whereKey($pid)
                    ->firstOrFail();

                $access->assertCanAttachPriceListToProject($user, $companyId, $project, $list);

                $exists = ProjectPriceList::query()
                    ->where('project_id', (int) $project->id)
                    ->where('price_list_id', (int) $list->id)
                    ->exists();

                if ($exists) {
                    continue;
                }

                $cp = $access->companyCounterparty((int) $user->id, $companyId);

                ProjectPriceList::query()->create([
                    'project_id' => (int) $project->id,
                    'price_list_id' => (int) $list->id,
                    'attached_by_user_id' => (int) $user->id,
                    'attached_by_counterparty_id' => $cp?->id,
                ]);

                $attached[] = (int) $list->id;
            }

            return $attached;
        });
    }

    public function detach(Project $project, int $priceListId): void
    {
        ProjectPriceList::query()
            ->where('project_id', (int) $project->id)
            ->where('price_list_id', $priceListId)
            ->delete();
    }

    private function creatorName(?PriceList $pl): string
    {
        if ($pl === null) {
            return '';
        }
        $pl->loadMissing(['createdByCounterparty', 'createdByUser']);
        $cp = $pl->createdByCounterparty;
        if ($cp !== null && trim((string) $cp->full_name) !== '') {
            return (string) $cp->full_name;
        }

        return (string) ($pl->createdByUser?->name ?? '');
    }
}
