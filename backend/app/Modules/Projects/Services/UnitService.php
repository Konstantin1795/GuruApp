<?php

namespace App\Modules\Projects\Services;

use App\Modules\Projects\Models\Unit;
use Illuminate\Support\Collection;

final class UnitService
{
    /**
     * @return Collection<int, Unit>
     */
    public function listSystemActive(): Collection
    {
        return Unit::query()
            ->where('is_active', true)
            ->where('is_system', true)
            ->whereNull('company_id')
            ->orderBy('id')
            ->get();
    }

    /**
     * @return list<array{id:int,name:string,short_name:string}>
     */
    public function toListPayloads(): array
    {
        return $this->listSystemActive()
            ->map(fn (Unit $u) => [
                'id' => $u->id,
                'name' => $u->name,
                'short_name' => $u->short_name,
            ])
            ->all();
    }
}
