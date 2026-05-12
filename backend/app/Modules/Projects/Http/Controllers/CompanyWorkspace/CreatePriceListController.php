<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Requests\StorePriceListRequest;
use App\Modules\Projects\Models\PriceList;
use App\Modules\Projects\Services\PriceListAccessService;
use App\Modules\Projects\Services\PriceListService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class CreatePriceListController
{
    public function __invoke(
        Request $request,
        StorePriceListRequest $body,
        PriceListAccessService $access,
        PriceListService $lists,
        int $companyId,
    ) {
        $user = $request->user();
        $access->assertCanCreatePriceList($user, $companyId);

        $cp = $access->companyCounterparty((int) $user->id, $companyId);
        if (! $cp) {
            abort(403, 'Forbidden.');
        }

        if (! $access->isOwner($cp)) {
            if ($access->activeOwnPriceListId($companyId, (int) $cp->id) !== null) {
                abort(422, 'You already have an active price list in this company.');
            }
        }

        $list = $lists->create($user, $companyId, (int) $cp->id, $body->validated()['name']);

        $list = $this->reloadWithCounts($list);

        return ApiResponse::ok([
            'price_list' => $lists->listItemPayload($list),
        ], [], 201);
    }

    private function reloadWithCounts(PriceList $list): PriceList
    {
        return PriceList::query()
            ->whereKey($list->id)
            ->with(['createdByCounterparty', 'createdByUser'])
            ->withCount([
                'groups as groups_count' => function ($gq): void {
                    $gq->where('is_active', true)->whereNull('deleted_at');
                },
                'positions as positions_count' => function ($pq): void {
                    $pq->where('is_active', true)->whereNull('deleted_at');
                },
            ])
            ->firstOrFail();
    }
}
