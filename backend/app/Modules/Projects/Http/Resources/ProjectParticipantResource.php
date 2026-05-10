<?php

namespace App\Modules\Projects\Http\Resources;

use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ProjectParticipant
 */
final class ProjectParticipantResource extends JsonResource
{
    /**
     * @return array<string,mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var ProjectParticipant $participant */
        $participant = $this->resource;

        $name = null;
        $email = null;

        if ($participant->relationLoaded('counterparty') && $participant->counterparty !== null) {
            $counterparty = $participant->counterparty;
            $name = $counterparty->full_name
                ?? optional($counterparty->relationLoaded('user') ? $counterparty->user : null)?->name;
            $email = $counterparty->email
                ?? optional($counterparty->relationLoaded('user') ? $counterparty->user : null)?->email;
        }

        $counterpartyUserId = null;
        if ($participant->relationLoaded('counterparty') && $participant->counterparty !== null) {
            $uid = $participant->counterparty->user_id;
            $counterpartyUserId = $uid !== null ? (int) $uid : null;
        }

        return [
            'id'               => $this->id,
            'project_id'       => $this->project_id,
            'counterparty_id'  => $this->counterparty_id,
            'counterparty_user_id' => $counterpartyUserId,
            'name'             => $name,
            'email'            => $email,
            'role'             => $this->project_role_code,
            'level'            => $this->level,
            'is_active'        => (bool) $this->is_active,
            'created_at'       => optional($this->created_at)?->toIso8601String(),
        ];
    }
}
