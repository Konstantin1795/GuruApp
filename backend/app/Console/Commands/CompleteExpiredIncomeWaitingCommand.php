<?php

namespace App\Console\Commands;

use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Services\IncomeLifecycleService;
use Illuminate\Console\Command;

final class CompleteExpiredIncomeWaitingCommand extends Command
{
    protected $signature = 'operations:complete-expired-income-waiting';

    protected $description = 'ТЗ-06: WAITING_24_HOURS → COMPLETED после 24 ч (UTC).';

    public function handle(IncomeLifecycleService $lifecycle): int
    {
        $done = 0;

        IncomeOperation::query()
            ->where('operation_status', OperationStatus::WAITING_24_HOURS)
            ->whereNotNull('waiting_period_started_at')
            ->orderBy('id')
            ->chunkById(100, function ($chunk) use ($lifecycle, &$done): void {
                foreach ($chunk as $income) {
                    if ($lifecycle->autoCompleteWaitingIfDue($income)) {
                        $done++;
                    }
                }
            });

        if ($done > 0) {
            $this->info("Автозавершено поступлений: {$done}.");
        }

        return self::SUCCESS;
    }
}
