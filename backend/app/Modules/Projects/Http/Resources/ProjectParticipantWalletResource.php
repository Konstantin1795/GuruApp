<?php

namespace App\Modules\Projects\Http\Resources;

use App\Modules\Projects\Models\ProjectParticipantWallet;
use App\Modules\Projects\Services\WalletBalanceService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ProjectParticipantWallet
 */
final class ProjectParticipantWalletResource extends JsonResource
{
    /**
     * @return array<string,mixed>
     */
    public function toArray(Request $request): array
    {
        $balanceService = app(WalletBalanceService::class);

        return $balanceService->getBalances($this->resource);
    }
}
