<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Modules\Operations\Enums\ReportOperationViewerMode;
use App\Modules\Operations\Http\Resources\ReportOperationResource;
use App\Modules\Operations\Models\ReportOperation;

/**
 * Сериализация REPORT для API с учётом роли зрителя (ТЗ-10C.1).
 */
final class ReportOperationApiPayloadFactory
{
    /**
     * @return array<string, mixed>
     */
    public function forReport(ReportOperation $report, ReportOperationViewerMode $mode): array
    {
        $full = (new ReportOperationResource($report))->resolve();

        return match ($mode) {
            ReportOperationViewerMode::Full => $full,
            ReportOperationViewerMode::Customer => $this->customerPayload($full),
            ReportOperationViewerMode::SecondOrderRecipient => $this->secondOrderRecipientPayload($full),
        };
    }

    /**
     * @param  array<string, mixed>  $full
     * @return array<string, mixed>
     */
    private function customerPayload(array $full): array
    {
        foreach ([
            'expense_item_id',
            'recipient_amount',
            'customer_base_amount',
            'markup_amount',
            'profit_amount',
            'initiator_project_participant_id',
            'recipient_counterparty_id',
            'recipient_project_participant_id',
            'customer_project_participant_id',
            'transfer_links',
        ] as $key) {
            unset($full[$key]);
        }

        if (isset($full['lines']) && is_array($full['lines'])) {
            $full['lines'] = array_map(
                static function (array $line): array {
                    foreach ([
                        'source_type',
                        'price_list_id',
                        'price_list_group_id',
                        'price_list_position_id',
                        'recipient_unit_price',
                        'recipient_total',
                    ] as $k) {
                        unset($line[$k]);
                    }

                    return $line;
                },
                $full['lines'],
            );
        }

        return $full;
    }

    /**
     * @param  array<string, mixed>  $full
     * @return array<string, mixed>
     */
    private function secondOrderRecipientPayload(array $full): array
    {
        foreach ([
            'expense_item_id',
            'customer_base_amount',
            'markup_amount',
            'profit_amount',
            'customer_total_amount',
        ] as $key) {
            unset($full[$key]);
        }

        if (isset($full['lines']) && is_array($full['lines'])) {
            $full['lines'] = array_map(
                static function (array $line): array {
                    unset($line['customer_unit_price'], $line['customer_total']);

                    return $line;
                },
                $full['lines'],
            );
        }

        return $full;
    }
}
