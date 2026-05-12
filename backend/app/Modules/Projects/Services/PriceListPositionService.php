<?php

namespace App\Modules\Projects\Services;

use App\Models\User;
use App\Modules\Projects\Models\PriceListGroup;
use App\Modules\Projects\Models\PriceListPosition;
use App\Modules\Projects\Models\Unit;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class PriceListPositionService
{
    public function paginateForGroup(
        PriceListGroup $group,
        ?string $search,
        int $page,
        int $perPage,
    ): LengthAwarePaginator {
        $q = PriceListPosition::query()
            ->where('price_list_group_id', (int) $group->id)
            ->visible()
            ->with('unit')
            ->orderBy('sort_order')
            ->orderBy('id');

        $search = $search !== null ? trim($search) : '';
        if ($search !== '') {
            $like = '%'.Str::lower($search).'%';
            $q->whereRaw('LOWER(service_name) LIKE ?', [$like]);
        }

        return $q->paginate(perPage: $perPage, page: $page);
    }

    public function findVisible(PriceListGroup $group, int $positionId): ?PriceListPosition
    {
        return PriceListPosition::query()
            ->where('price_list_group_id', (int) $group->id)
            ->whereKey($positionId)
            ->visible()
            ->with('unit')
            ->first();
    }

    /**
     * @param array{service_name: string, unit_id: int, recipient_unit_price: string, customer_unit_price: string} $data
     */
    public function create(User $user, PriceListGroup $group, array $data): PriceListPosition
    {
        $this->validateUnit((int) $group->price_list_id, (int) $data['unit_id']);
        $this->validatePrices($data['recipient_unit_price'], $data['customer_unit_price']);

        return DB::transaction(function () use ($user, $group, $data): PriceListPosition {
            $max = (int) PriceListPosition::query()
                ->where('price_list_group_id', (int) $group->id)
                ->max('sort_order');

            $position = new PriceListPosition([
                'price_list_id' => (int) $group->price_list_id,
                'price_list_group_id' => (int) $group->id,
                'service_name' => trim($data['service_name']),
                'unit_id' => (int) $data['unit_id'],
                'recipient_unit_price' => PriceListPricing::normalizeMoney($data['recipient_unit_price']),
                'customer_unit_price' => PriceListPricing::normalizeMoney($data['customer_unit_price']),
                'sort_order' => $max + 1,
                'is_active' => true,
                'created_by_user_id' => (int) $user->id,
                'updated_by_user_id' => (int) $user->id,
            ]);
            $position->save();

            return $position->load('unit');
        });
    }

    /**
     * @param array{service_name?: string, unit_id?: int, recipient_unit_price?: string, customer_unit_price?: string} $data
     */
    public function update(User $user, PriceListPosition $position, array $data): PriceListPosition
    {
        if (array_key_exists('service_name', $data)) {
            $position->service_name = trim((string) $data['service_name']);
            if ($position->service_name === '') {
                abort(422, 'service_name is required.');
            }
        }

        if (array_key_exists('unit_id', $data)) {
            $this->validateUnit((int) $position->price_list_id, (int) $data['unit_id']);
            $position->unit_id = (int) $data['unit_id'];
        }

        if (array_key_exists('recipient_unit_price', $data) || array_key_exists('customer_unit_price', $data)) {
            $recipient = PriceListPricing::normalizeMoney(
                (string) ($data['recipient_unit_price'] ?? $position->recipient_unit_price),
            );
            $customer = PriceListPricing::normalizeMoney(
                (string) ($data['customer_unit_price'] ?? $position->customer_unit_price),
            );
            $this->validatePrices($recipient, $customer);
            $position->recipient_unit_price = $recipient;
            $position->customer_unit_price = $customer;
        }

        $position->updated_by_user_id = (int) $user->id;
        $position->save();

        return $position->load('unit');
    }

    public function delete(PriceListPosition $position, PriceListDeletionService $deletion): void
    {
        $deletion->deletePosition($position);
    }

    /**
     * @return array<string, mixed>
     */
    public function toPayload(PriceListPosition $position): array
    {
        $position->loadMissing('unit');
        $profit = PriceListPricing::profit(
            (string) $position->recipient_unit_price,
            (string) $position->customer_unit_price,
        );

        return [
            'id' => $position->id,
            'service_name' => $position->service_name,
            'unit' => $position->unit !== null ? [
                'id' => $position->unit->id,
                'name' => $position->unit->name,
                'short_name' => $position->unit->short_name,
            ] : null,
            'recipient_unit_price' => (string) $position->recipient_unit_price,
            'customer_unit_price' => (string) $position->customer_unit_price,
            'profit_amount' => $profit['profit_amount'],
            'profit_percent' => $profit['profit_percent'],
            'sort_order' => (int) $position->sort_order,
        ];
    }

    private function validateUnit(int $priceListId, int $unitId): void
    {
        \App\Modules\Projects\Models\PriceList::query()->whereKey($priceListId)->firstOrFail();

        $ok = Unit::query()
            ->whereKey($unitId)
            ->where('is_active', true)
            ->where('is_system', true)
            ->whereNull('company_id')
            ->exists();

        if (! $ok) {
            abort(422, 'Invalid unit.');
        }
    }

    private function validatePrices(string $recipient, string $customer): void
    {
        if (bccomp($recipient, '0', 2) <= 0) {
            abort(422, 'recipient_unit_price must be greater than 0.');
        }

        if (bccomp($customer, '0', 2) < 0) {
            abort(422, 'customer_unit_price must be >= 0.');
        }
    }
}
