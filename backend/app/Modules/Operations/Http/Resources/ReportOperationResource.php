<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Resources;

use App\Modules\Operations\Models\ReportOperation;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ReportOperation
 */
final class ReportOperationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var ReportOperation $report */
        $report = $this->resource;

        return [
            'id' => $report->id,
            'operation_number' => $report->operation_number,
            'company_id' => $report->company_id,
            'project_id' => $report->project_id,
            'initiator_project_participant_id' => $report->initiator_project_participant_id,
            'recipient_counterparty_id' => $report->recipient_counterparty_id,
            'recipient_project_participant_id' => $report->recipient_project_participant_id,
            'customer_project_participant_id' => $report->customer_project_participant_id,
            'expense_item_id' => $report->expense_item_id,
            'operation_date' => $report->operation_date?->format('Y-m-d'),
            'operation_status' => $report->operation_status->value,
            'recipient_amount' => (string) $report->recipient_amount,
            'customer_base_amount' => (string) $report->customer_base_amount,
            'markup_amount' => (string) $report->markup_amount,
            'customer_total_amount' => (string) $report->customer_total_amount,
            'profit_amount' => (string) $report->profit_amount,
            'comment' => $report->comment,
            'wallets_applied_at' => optional($report->wallets_applied_at)?->toIso8601String(),
            'wallets_reverted_at' => optional($report->wallets_reverted_at)?->toIso8601String(),
            'waiting_period_started_at' => optional($report->waiting_period_started_at)?->toIso8601String(),
            'completed_at' => optional($report->completed_at)?->toIso8601String(),
            'created_at' => optional($report->created_at)?->toIso8601String(),
            'updated_at' => optional($report->updated_at)?->toIso8601String(),
            'project_name' => $this->when(
                $report->relationLoaded('project') && $report->project,
                fn () => $report->project->name,
            ),
            'lines' => $this->when(
                $report->relationLoaded('lines'),
                fn () => $report->lines->map(static fn ($line) => [
                    'id' => $line->id,
                    'source_type' => $line->source_type->value,
                    'price_list_id' => $line->price_list_id,
                    'price_list_group_id' => $line->price_list_group_id,
                    'price_list_position_id' => $line->price_list_position_id,
                    'name' => $line->name,
                    'unit_id' => $line->unit_id,
                    'unit_name' => $line->unit_name,
                    'unit_short_name' => $line->unit_short_name,
                    'quantity' => (string) $line->quantity,
                    'recipient_unit_price' => (string) $line->recipient_unit_price,
                    'customer_unit_price' => (string) $line->customer_unit_price,
                    'recipient_total' => (string) $line->recipient_total,
                    'customer_total' => (string) $line->customer_total,
                    'sort_order' => $line->sort_order,
                ])->all(),
            ),
            'transfer_links' => $this->when(
                $report->relationLoaded('transferLinks'),
                fn () => ReportTransferLinkResource::collection($report->transferLinks)->resolve(),
            ),
        ];
    }
}
