<?php

namespace App\Modules\Projects\Services;

use App\Models\User;
use App\Modules\Projects\Models\PriceList;
use App\Modules\Projects\Models\PriceListGroup;
use App\Modules\Projects\Models\PriceListPosition;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class PriceListService
{
    public function __construct(
        private readonly PriceListDeletionService $deletion,
    ) {}

    public function paginateForCompany(
        PriceListAccessService $access,
        User $user,
        int $companyId,
        ?string $search,
        int $page,
        int $perPage,
    ): LengthAwarePaginator {
        $q = $access->priceListsIndexQuery($user, $companyId)
            ->with(['createdByCounterparty', 'createdByUser'])
            ->withCount([
                'groups as groups_count' => function ($gq): void {
                    $gq->where('is_active', true)->whereNull('deleted_at');
                },
                'positions as positions_count' => function ($pq): void {
                    $pq->where('is_active', true)->whereNull('deleted_at');
                },
            ])
            ->orderByDesc('id');

        $search = $search !== null ? trim($search) : '';
        if ($search !== '') {
            $like = '%'.Str::lower($search).'%';
            $q->whereRaw('LOWER(price_lists.name) LIKE ?', [$like]);
        }

        return $q->paginate(perPage: $perPage, page: $page);
    }

    public function findVisibleInCompany(int $companyId, int $priceListId): ?PriceList
    {
        return PriceList::query()
            ->where('company_id', $companyId)
            ->whereKey($priceListId)
            ->visible()
            ->first();
    }

    public function detailPayload(PriceList $priceList, ?bool $canEdit = null): array
    {
        $priceList->loadMissing(['createdByCounterparty', 'createdByUser']);

        $payload = [
            'id' => $priceList->id,
            'name' => $priceList->name,
            'is_active' => (bool) $priceList->is_active,
            'creator_display_name' => $this->creatorDisplayName($priceList),
            'created_by_counterparty_id' => $priceList->created_by_counterparty_id,
            'groups' => $priceList->groups()
                ->visible()
                ->orderBy('sort_order')
                ->orderBy('id')
                ->get()
                ->map(fn (PriceListGroup $g) => $this->groupSummary($g)),
        ];

        if ($canEdit !== null) {
            $payload['can_edit'] = $canEdit;
        }

        return $payload;
    }

    public function listItemPayload(PriceList $priceList): array
    {
        $priceList->loadMissing(['createdByCounterparty', 'createdByUser']);

        return [
            'id' => $priceList->id,
            'name' => $priceList->name,
            'creator_display_name' => $this->creatorDisplayName($priceList),
            'groups_count' => (int) ($priceList->groups_count ?? 0),
            'positions_count' => (int) ($priceList->positions_count ?? 0),
        ];
    }

    public function create(User $user, int $companyId, int $counterpartyId, string $name): PriceList
    {
        $name = trim($name);
        if ($name === '') {
            abort(422, 'Name is required.');
        }

        $this->assertUniqueActiveName($companyId, $name, null);

        return DB::transaction(function () use ($user, $companyId, $counterpartyId, $name): PriceList {
            $list = new PriceList([
                'company_id' => $companyId,
                'name' => $name,
                'is_active' => true,
                'created_by_user_id' => (int) $user->id,
                'created_by_counterparty_id' => $counterpartyId,
                'updated_by_user_id' => (int) $user->id,
            ]);
            $list->save();

            return $list;
        });
    }

    public function update(User $user, PriceList $priceList, string $name): PriceList
    {
        $name = trim($name);
        if ($name === '') {
            abort(422, 'Name is required.');
        }

        $this->assertUniqueActiveName((int) $priceList->company_id, $name, (int) $priceList->id);

        $priceList->name = $name;
        $priceList->updated_by_user_id = (int) $user->id;
        $priceList->save();

        return $priceList;
    }

    /**
     * @return array{deleted_mode: string, detached_projects_count: int}
     */
    public function delete(PriceList $priceList): array
    {
        return $this->deletion->deletePriceList($priceList);
    }

    private function assertUniqueActiveName(int $companyId, string $name, ?int $ignoreId): void
    {
        $q = PriceList::query()
            ->where('company_id', $companyId)
            ->visible()
            ->whereRaw('LOWER(name) = ?', [Str::lower($name)]);

        if ($ignoreId !== null) {
            $q->where('id', '!=', $ignoreId);
        }

        if ($q->exists()) {
            abort(422, 'A price list with this name already exists.');
        }
    }

    private function creatorDisplayName(PriceList $priceList): string
    {
        $cp = $priceList->createdByCounterparty;
        if ($cp !== null && trim((string) $cp->full_name) !== '') {
            return (string) $cp->full_name;
        }

        $u = $priceList->createdByUser;

        return $u !== null ? (string) $u->name : '';
    }

    /**
     * @return array{id:int,name:string,sort_order:int,positions_count:int}
     */
    private function groupSummary(PriceListGroup $g): array
    {
        return [
            'id' => $g->id,
            'name' => $g->name,
            'sort_order' => (int) $g->sort_order,
            'positions_count' => $g->positions()->visible()->count(),
        ];
    }
}
