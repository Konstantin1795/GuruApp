<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Operations\Models\ReportWalletDelta;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectExpenseItem;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Models\ProjectParticipantWallet;
use App\Modules\Projects\Services\WalletService;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Проведение и откат дельт REPORT с записью в {@see ReportWalletDelta}.
 */
final class ReportBalanceService
{
    public function __construct(
        private readonly WalletService $walletService,
    ) {}

    /**
     * @throws ValidationException
     */
    public function applyReportDeltas(ReportOperation $report): void
    {
        if ($report->wallets_applied_at !== null) {
            throw ValidationException::withMessages([
                'report' => ['Финансовые дельты уже применены.'],
            ]);
        }

        $report->loadMissing([
            'customerParticipant',
            'recipientParticipant',
            'expenseItem.profitShares',
            'expenseItem.markupShares',
        ]);

        $expenseItem = $report->expenseItem;
        if (! $expenseItem instanceof ProjectExpenseItem) {
            throw ValidationException::withMessages(['report' => ['Статья расходов не найдена.']]);
        }

        $customer = $report->customerParticipant;
        $recipient = $report->recipientParticipant;
        if (! $customer || ! $recipient) {
            throw ValidationException::withMessages(['report' => ['Участники отчёта не загружены.']]);
        }

        $customerTotalCents = $this->toCents((string) $report->customer_total_amount);
        $recipientAmountCents = $this->toCents((string) $report->recipient_amount);
        $profitCents = $this->toCents((string) $report->profit_amount);
        $markupCents = $this->toCents((string) $report->markup_amount);

        DB::transaction(function () use (
            $report,
            $expenseItem,
            $customer,
            $recipient,
            $customerTotalCents,
            $recipientAmountCents,
            $profitCents,
            $markupCents,
        ): void {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();
            if ($fresh->wallets_applied_at !== null) {
                throw ValidationException::withMessages(['report' => ['Финансовые дельты уже применены.']]);
            }

            $utcNow = Carbon::now('UTC');

            $cw = $this->walletService->ensureWallet($customer);
            $cw = $cw->newQuery()->whereKey($cw->id)->lockForUpdate()->firstOrFail();
            $this->adjustWalletField($fresh, $customer, $cw, 'accountable_balance', -$customerTotalCents, $utcNow);

            $rw = $this->walletService->ensureWallet($recipient);
            $rw = $rw->newQuery()->whereKey($rw->id)->lockForUpdate()->firstOrFail();
            $this->adjustWalletField($fresh, $recipient, $rw, 'personal_earned', $recipientAmountCents, $utcNow);

            $profitShares = $expenseItem->relationLoaded('profitShares')
                ? $expenseItem->profitShares
                : $expenseItem->profitShares()->get();

            $allocatedProfit = $this->allocateCentsByPercents($profitCents, $profitShares->map(fn ($s) => (string) $s->percent)->all());
            foreach ($profitShares as $idx => $share) {
                $cents = $allocatedProfit[$idx] ?? 0;
                if ($cents === 0) {
                    continue;
                }
                $participant = $this->resolveShareParticipant($fresh, (int) $share->counterparty_id);
                $w = $this->walletService->ensureWallet($participant);
                $w = $w->newQuery()->whereKey($w->id)->lockForUpdate()->firstOrFail();
                $this->adjustWalletField($fresh, $participant, $w, 'personal_earned', $cents, $utcNow);
            }

            if ($markupCents > 0) {
                $markupShares = $expenseItem->relationLoaded('markupShares')
                    ? $expenseItem->markupShares
                    : $expenseItem->markupShares()->get();

                $allocatedMarkup = $this->allocateCentsByPercents($markupCents, $markupShares->map(fn ($s) => (string) $s->percent)->all());
                foreach ($markupShares as $idx => $share) {
                    $cents = $allocatedMarkup[$idx] ?? 0;
                    if ($cents === 0) {
                        continue;
                    }
                    $participant = $this->resolveShareParticipant($fresh, (int) $share->counterparty_id);
                    $w = $this->walletService->ensureWallet($participant);
                    $w = $w->newQuery()->whereKey($w->id)->lockForUpdate()->firstOrFail();
                    $this->adjustWalletField($fresh, $participant, $w, 'personal_earned', $cents, $utcNow);
                }
            }

            $fresh->update([
                'wallets_applied_at'  => $utcNow,
                'wallets_reverted_at' => null,
            ]);
        });
    }

    /**
     * @throws ValidationException
     */
    public function revertReportDeltas(ReportOperation $report): void
    {
        if ($report->wallets_applied_at === null) {
            throw ValidationException::withMessages([
                'report' => ['Нечего откатывать: дельты не применялись.'],
            ]);
        }

        DB::transaction(function () use ($report): void {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();
            $utcNow = Carbon::now('UTC');

            $deltas = ReportWalletDelta::query()
                ->where('report_operation_id', $fresh->id)
                ->whereNull('reverted_at')
                ->orderBy('id')
                ->lockForUpdate()
                ->get();

            foreach ($deltas as $delta) {
                $participant = ProjectParticipant::query()->whereKey($delta->project_participant_id)->firstOrFail();
                $w = $this->walletService->ensureWallet($participant);
                $w = $w->newQuery()->whereKey($w->id)->lockForUpdate()->firstOrFail();
                $this->applySignedCentsToField($w, $delta->field_name, -((int) $delta->delta_cents));
                $delta->update(['reverted_at' => $utcNow]);
            }

            $fresh->update([
                'wallets_reverted_at' => $utcNow,
                'wallets_applied_at'  => null,
            ]);
        });
    }

    private function adjustWalletField(
        ReportOperation $report,
        ProjectParticipant $participant,
        ProjectParticipantWallet $wallet,
        string $field,
        int $signedDeltaCents,
        Carbon $appliedAt,
    ): void {
        $this->applySignedCentsToField($wallet, $field, $signedDeltaCents);

        ReportWalletDelta::query()->create([
            'report_operation_id'      => $report->id,
            'project_participant_id'   => $participant->id,
            'wallet_id'                => $wallet->id,
            'field_name'               => $field,
            'delta_cents'              => $signedDeltaCents,
            'applied_at'               => $appliedAt,
            'reverted_at'              => null,
        ]);
    }

    private function applySignedCentsToField(ProjectParticipantWallet $wallet, string $field, int $deltaCents): void
    {
        $allowed = ['accountable_balance', 'personal_earned'];
        if (! in_array($field, $allowed, true)) {
            throw ValidationException::withMessages(['report' => ['Недопустимое поле кошелька для REPORT.']]);
        }

        $current = $this->walletBalanceToCents($wallet->{$field});
        $newVal = $this->fromCents($current + $deltaCents);
        $wallet->update([$field => $newVal]);
    }

    /**
     * @param  list<string>  $percents  строки вида "33.33"
     * @return list<int> распределённые центы, сумма = $totalCents
     */
    private function allocateCentsByPercents(int $totalCents, array $percents): array
    {
        if ($totalCents === 0) {
            return array_fill(0, count($percents), 0);
        }

        $n = count($percents);
        if ($n === 0) {
            return [];
        }

        $parts = [];
        $allocated = 0;
        foreach ($percents as $i => $p) {
            $pc = $this->percentToBasisPoints((string) $p);
            $raw = (int) floor(($totalCents * $pc) / 10000);
            $parts[$i] = $raw;
            $allocated += $raw;
        }

        $remainder = $totalCents - $allocated;
        for ($j = 0; $remainder !== 0 && $j < $n; $j++) {
            $idx = $j % $n;
            $step = $remainder > 0 ? 1 : -1;
            $parts[$idx] += $step;
            $remainder -= $step;
        }

        return $parts;
    }

    private function percentToBasisPoints(string $percent): int
    {
        $percent = trim($percent);
        if (! preg_match('/^\d+(\.\d+)?$/', $percent)) {
            throw ValidationException::withMessages(['percent' => ['Некорректный процент.']]);
        }

        return (int) round(((float) $percent) * 100);
    }

    private function resolveShareParticipant(ReportOperation $report, int $counterpartyId): ProjectParticipant
    {
        $p = ProjectParticipant::query()
            ->where('project_id', $report->project_id)
            ->where('counterparty_id', $counterpartyId)
            ->where('is_active', true)
            ->first();

        if ($p) {
            return $p;
        }

        $project = $report->project ?? Project::query()->whereKey($report->project_id)->firstOrFail();
        $customerCpId = (int) ProjectParticipant::query()
            ->whereKey($report->customer_project_participant_id)
            ->value('counterparty_id');

        return app(ReportParticipantResolver::class)->resolveRecipientParticipant(
            $project,
            (int) $project->company_id,
            $counterpartyId,
            $customerCpId,
        );
    }

    private function walletBalanceToCents(mixed $raw): int
    {
        if ($raw === null) {
            return 0;
        }
        if (is_float($raw)) {
            return $this->toCents(sprintf('%.2f', $raw));
        }

        $s = trim((string) $raw);
        if ($s === '') {
            return 0;
        }

        return $this->toCents($s);
    }

    /**
     * @throws ValidationException
     */
    private function toCents(string $amount): int
    {
        $value = trim($amount);
        $negative = str_starts_with($value, '-');
        if ($negative) {
            $value = substr($value, 1);
        }

        if (! preg_match('/^\d+(\.\d{1,2})?$/', $value)) {
            throw ValidationException::withMessages([
                'amount' => ['Некорректный формат суммы.'],
            ]);
        }

        [$whole, $fraction] = array_pad(explode('.', $value, 2), 2, '0');
        $fraction = str_pad(substr($fraction, 0, 2), 2, '0');

        $cents = ((int) $whole * 100) + (int) $fraction;

        return $negative ? -$cents : $cents;
    }

    private function fromCents(int $cents): string
    {
        $sign = $cents < 0 ? '-' : '';
        $absolute = abs($cents);
        $whole = intdiv($absolute, 100);
        $fraction = $absolute % 100;

        return sprintf('%s%d.%02d', $sign, $whole, $fraction);
    }
}
