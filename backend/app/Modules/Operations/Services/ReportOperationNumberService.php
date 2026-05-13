<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Operations\Models\TransferOperation;

final class ReportOperationNumberService
{
    public function assignReportNumber(ReportOperation $report): void
    {
        if ($report->operation_number !== null && $report->operation_number !== '') {
            return;
        }

        $report->update(['operation_number' => 'REP-'.$report->id]);
    }

    public function assignTransferNumber(TransferOperation $transfer): void
    {
        if ($transfer->operation_number !== null && $transfer->operation_number !== '') {
            return;
        }

        $transfer->update(['operation_number' => 'TRF-'.$transfer->id]);
    }
}
