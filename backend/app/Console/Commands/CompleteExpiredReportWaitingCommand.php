<?php

namespace App\Console\Commands;

use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Operations\Services\ReportLifecycleService;
use Illuminate\Console\Command;

final class CompleteExpiredReportWaitingCommand extends Command
{
    protected $signature = 'operations:complete-expired-report-waiting';

    protected $description = 'ТЗ-10C: REPORT WAITING_24_HOURS → COMPLETED после 24 ч (UTC).';

    public function handle(ReportLifecycleService $lifecycle): int
    {
        $done = 0;

        ReportOperation::query()
            ->where('operation_status', OperationStatus::WAITING_24_HOURS)
            ->whereNotNull('waiting_period_started_at')
            ->orderBy('id')
            ->chunkById(100, function ($chunk) use ($lifecycle, &$done): void {
                foreach ($chunk as $report) {
                    if ($lifecycle->autoCompleteWaitingIfDue($report)) {
                        $done++;
                    }
                }
            });

        if ($done > 0) {
            $this->info("Автозавершено отчётов: {$done}.");
        }

        return self::SUCCESS;
    }
}
