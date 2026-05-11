<?php

namespace App\Modules\Operations\Http\Resources;

use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin IncomeOperation
 */
final class IncomeOperationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var IncomeOperation $income */
        $income = $this->resource;

        return [
            'id'             => $income->id,
            'operation_id'   => $income->operation_id,
            'project_id'     => $income->project_id,
            'amount'         => (string) $income->amount,
            'comment'        => $income->comment,
            'operation_status' => $income->operation_status->value,
            'wallets_applied_at' => optional($income->wallets_applied_at)?->toIso8601String(),
            'wallets_reverted_at' => optional($income->wallets_reverted_at)?->toIso8601String(),
            'waiting_period_started_at' => optional($income->waiting_period_started_at)?->toIso8601String(),
            'created_at'     => optional($income->created_at)?->toIso8601String(),
            'updated_at'     => optional($income->updated_at)?->toIso8601String(),
            'project_name'   => $this->when(
                $income->relationLoaded('project') && $income->project,
                fn () => $income->project->name,
            ),
            'initiator'      => $this->participantBlock($income, 'initiator', withRole: true),
            'project_head'   => $this->participantBlock($income, 'projectHead', withRole: false),
            'customer'       => $this->participantBlock($income, 'customer', withRole: false),
            'status_history' => $this->when(
                $income->relationLoaded('operation')
                    && $income->operation
                    && $income->operation->relationLoaded('statusHistory'),
                fn () => OperationStatusHistoryResource::collection($income->operation->statusHistory)->resolve(),
            ),
        ];
    }

    /**
     * @return array<string, mixed>|null
     */
    private function participantBlock(IncomeOperation $income, string $relation, bool $withRole): ?array
    {
        if (! $income->relationLoaded($relation)) {
            return null;
        }

        /** @var ProjectParticipant|null $p */
        $p = $income->{$relation};
        if (! $p) {
            return null;
        }

        $name = null;
        if ($p->relationLoaded('counterparty') && $p->counterparty) {
            $c = $p->counterparty;
            $name = $c->full_name
                ?? optional($c->relationLoaded('user') ? $c->user : null)?->name
                ?? $c->email
                ?? optional($c->relationLoaded('user') ? $c->user : null)?->email;
        }

        $out = [
            'project_participant_id' => $p->id,
            'full_name'              => $name,
        ];

        if ($withRole) {
            $out['project_role_code'] = $p->project_role_code;
        }

        return $out;
    }
}
