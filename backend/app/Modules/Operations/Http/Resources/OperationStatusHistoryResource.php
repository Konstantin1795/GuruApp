<?php

namespace App\Modules\Operations\Http\Resources;

use App\Modules\Operations\Models\OperationStatusHistory;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin OperationStatusHistory
 */
final class OperationStatusHistoryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var OperationStatusHistory $h */
        $h = $this->resource;

        return [
            'id'                 => $h->id,
            'from_status'        => $h->from_status?->value,
            'to_status'          => $h->to_status->value,
            'comment'            => $h->comment,
            'author_user_id'     => $h->author_user_id,
            'author_full_name'   => $h->author_full_name,
            'created_at'         => $h->created_at?->toIso8601String(),
        ];
    }
}
