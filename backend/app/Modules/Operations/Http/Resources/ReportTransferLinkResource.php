<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Resources;

use App\Modules\Operations\Models\ReportTransferLink;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ReportTransferLink
 */
final class ReportTransferLinkResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var ReportTransferLink $link */
        $link = $this->resource;

        return [
            'id' => $link->id,
            'transfer' => new TransferOperationResource($link->transferOperation),
        ];
    }
}
