<?php

namespace App\Modules\Projects\Services;

use App\Models\User;
use App\Modules\Projects\Models\PriceList;
use App\Modules\Projects\Models\PriceListGroup;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class PriceListGroupService
{
    public function paginateForPriceList(
        PriceList $priceList,
        ?string $search,
        int $page,
        int $perPage,
    ): LengthAwarePaginator {
        $q = PriceListGroup::query()
            ->where('price_list_id', (int) $priceList->id)
            ->visible()
            ->orderBy('sort_order')
            ->orderBy('id');

        $search = $search !== null ? trim($search) : '';
        if ($search !== '') {
            $like = '%'.Str::lower($search).'%';
            $q->whereRaw('LOWER(name) LIKE ?', [$like]);
        }

        return $q->paginate(perPage: $perPage, page: $page);
    }

    public function findVisible(PriceList $priceList, int $groupId): ?PriceListGroup
    {
        return PriceListGroup::query()
            ->where('price_list_id', (int) $priceList->id)
            ->whereKey($groupId)
            ->visible()
            ->first();
    }

    public function create(User $user, PriceList $priceList, string $name): PriceListGroup
    {
        $name = trim($name);
        if ($name === '') {
            abort(422, 'Name is required.');
        }

        return DB::transaction(function () use ($user, $priceList, $name): PriceListGroup {
            $max = (int) PriceListGroup::query()
                ->where('price_list_id', (int) $priceList->id)
                ->max('sort_order');

            $group = new PriceListGroup([
                'price_list_id' => (int) $priceList->id,
                'name' => $name,
                'sort_order' => $max + 1,
                'is_active' => true,
                'created_by_user_id' => (int) $user->id,
                'updated_by_user_id' => (int) $user->id,
            ]);
            $group->save();

            return $group;
        });
    }

    public function update(User $user, PriceListGroup $group, string $name): PriceListGroup
    {
        $name = trim($name);
        if ($name === '') {
            abort(422, 'Name is required.');
        }

        $group->name = $name;
        $group->updated_by_user_id = (int) $user->id;
        $group->save();

        return $group;
    }

    public function delete(PriceListGroup $group, PriceListDeletionService $deletion): void
    {
        $deletion->deleteGroup($group);
    }

    public function toListPayload(PriceListGroup $group): array
    {
        return [
            'id' => $group->id,
            'name' => $group->name,
            'sort_order' => (int) $group->sort_order,
        ];
    }
}
