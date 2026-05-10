<?php

namespace App\Console\Commands;

use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\TransferOperation;
use App\Modules\Operations\Services\TransferLifecycleService;
use Illuminate\Console\Command;

final class CompleteExpiredTransferWaitingCommand extends Command
{
    protected $signature = 'operations:complete-expired-transfer-waiting';

    protected $description = 'ТЗ-05.2 §19: WAITING_24_HOURS → COMPLETED после 24 ч (UTC от waiting_period_started_at).';

    public function handle(TransferLifecycleService $lifecycle): int
    {
        $done = 0;

        TransferOperation::query()
            ->where('operation_status', OperationStatus::WAITING_24_HOURS)
            ->whereNotNull('waiting_period_started_at')
            ->orderBy('id')
            ->chunkById(100, function ($chunk) use ($lifecycle, &$done): void {
                foreach ($chunk as $transfer) {
                    if ($lifecycle->autoCompleteWaitingIfDue($transfer)) {
                        $done++;
                    }
                }
            });

        if ($done > 0) {
            $this->info("Автозавершено переводов: {$done}.");
        }

        return self::SUCCESS;
    }
}
