<?php

namespace App\Modules\Operations\Http\Resources;

use App\Modules\Operations\Models\TransferOperation;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TransferOperation
 */
final class TransferOperationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var TransferOperation $transfer */
        $transfer = $this->resource;

        return [
            'id' => $transfer->id,
            'operation_number' => $transfer->operation_number,
            'operation_id' => $transfer->operation_id,
            'project_id' => $transfer->project_id,
            'initiator_project_participant_id' => $transfer->initiator_project_participant_id,
            'sender_project_participant_id' => $transfer->sender_project_participant_id,
            'receiver_project_participant_id' => $transfer->receiver_project_participant_id,
            'receiver_counterparty_id' => $transfer->receiver_counterparty_id,
            'sender_name' => $this->participantName($transfer, 'sender'),
            'receiver_name' => $this->participantName($transfer, 'receiver'),
            'transfer_target_type' => $transfer->transfer_target_type->value,
            'amount' => (string) $transfer->amount,
            'comment' => $transfer->comment,
            'operation_status' => $transfer->operation_status->value,
            'wallets_applied_at' => optional($transfer->wallets_applied_at)?->toIso8601String(),
            'wallets_reverted_at' => optional($transfer->wallets_reverted_at)?->toIso8601String(),
            'waiting_period_started_at' => optional($transfer->waiting_period_started_at)?->toIso8601String(),
            'created_at' => optional($transfer->created_at)?->toIso8601String(),
            'updated_at' => optional($transfer->updated_at)?->toIso8601String(),
            'linked_report' => $this->when(
                $transfer->relationLoaded('reportTransferLink'),
                function () use ($transfer): ?array {
                    $link = $transfer->reportTransferLink;
                    if ($link === null) {
                        return null;
                    }
                    $link->loadMissing('reportOperation');

                    return [
                        'report_id' => (int) $link->report_operation_id,
                        'operation_number' => $link->reportOperation?->operation_number,
                    ];
                },
            ),
            'project_name' => $this->when(
                $transfer->relationLoaded('project') && $transfer->project,
                fn () => $transfer->project->name,
            ),
            'status_history' => $this->when(
                $transfer->relationLoaded('operation')
                    && $transfer->operation
                    && $transfer->operation->relationLoaded('statusHistory'),
                fn () => OperationStatusHistoryResource::collection($transfer->operation->statusHistory)->resolve(),
            ),
        ];
    }

    private function participantName(TransferOperation $transfer, string $relation): ?string
    {
        if (! $transfer->relationLoaded($relation)) {
            return null;
        }

        /** @var ProjectParticipant|null $participant */
        $participant = $transfer->{$relation};
        if (! $participant || ! $participant->relationLoaded('counterparty') || ! $participant->counterparty) {
            return null;
        }

        $counterparty = $participant->counterparty;

        return $counterparty->full_name
            ?? optional($counterparty->relationLoaded('user') ? $counterparty->user : null)?->name
            ?? $counterparty->email
            ?? optional($counterparty->relationLoaded('user') ? $counterparty->user : null)?->email;
    }
}
