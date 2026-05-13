<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Models\User;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Operations\Models\ReportTransferLink;
use App\Modules\Operations\Models\TransferOperation;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class ReportTransferLinkService
{
    public function __construct(
        private readonly ReportAccessService $access,
    ) {}

    /**
     * @throws ValidationException
     */
    public function attachByTransferOperationNumber(
        ReportOperation $report,
        ProjectParticipant $actor,
        User $user,
        string $operationNumberRaw,
    ): ReportTransferLink {
        $this->access->assertCanEditReport($report, $actor);

        $transferId = $this->parseTransferOperationNumber($operationNumberRaw);
        if ($transferId === null) {
            throw ValidationException::withMessages([
                'operation_number' => ['Укажите номер перевода в формате TRF-{id} или числовой id.'],
            ]);
        }

        $transfer = TransferOperation::query()->whereKey($transferId)->first();
        if (! $transfer || (int) $transfer->project_id !== (int) $report->project_id) {
            throw ValidationException::withMessages([
                'operation_number' => ['Перевод не найден или относится к другому проекту.'],
            ]);
        }

        if (ReportTransferLink::query()->where('transfer_operation_id', $transfer->id)->exists()) {
            throw ValidationException::withMessages([
                'operation_number' => ['Этот перевод уже прикреплён к отчёту.'],
            ]);
        }

        return DB::transaction(function () use ($report, $transfer, $user): ReportTransferLink {
            $link = ReportTransferLink::query()->create([
                'report_operation_id'   => $report->id,
                'transfer_operation_id' => $transfer->id,
                'created_by_user_id'    => $user->id,
            ]);

            return $link->fresh()->load([
                'transferOperation.sender.counterparty.user',
                'transferOperation.receiver.counterparty.user',
                'transferOperation.project',
            ]);
        });
    }

    /**
     * @return Collection<int, ReportTransferLink>
     */
    public function listForReport(ReportOperation $report): Collection
    {
        return ReportTransferLink::query()
            ->where('report_operation_id', $report->id)
            ->with([
                'transferOperation.sender.counterparty.user',
                'transferOperation.receiver.counterparty.user',
                'transferOperation.project',
            ])
            ->orderBy('id')
            ->get();
    }

    /**
     * @throws ValidationException
     */
    public function detach(ReportOperation $report, ProjectParticipant $actor, int $linkId): void
    {
        $this->access->assertCanEditReport($report, $actor);

        $deleted = ReportTransferLink::query()
            ->where('report_operation_id', $report->id)
            ->whereKey($linkId)
            ->delete();

        if ($deleted === 0) {
            throw ValidationException::withMessages([
                'link' => ['Связь не найдена.'],
            ]);
        }
    }

    private function parseTransferOperationNumber(string $raw): ?int
    {
        $trim = trim($raw);
        if ($trim === '') {
            return null;
        }

        if (preg_match('/^TRF-(\d+)$/i', $trim, $m)) {
            return (int) $m[1];
        }

        if (preg_match('/^\d+$/', $trim)) {
            return (int) $trim;
        }

        return null;
    }
}
