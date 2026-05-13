<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Models\User;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Enums\ReportLineSourceType;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Operations\Models\ReportOperationLine;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectExpenseItem;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class ReportService
{
    public function __construct(
        private readonly ReportParticipantResolver $participantResolver,
        private readonly ReportAccessService $access,
        private readonly ReportOperationNumberService $numberService,
    ) {}

    /**
     * @param  array{
     *   expense_item_id:int,
     *   recipient_counterparty_id:int,
     *   operation_date:string,
     *   comment?:string|null,
     *   lines:list<array<string,mixed>>
     * }  $payload
     */
    public function create(
        Project $project,
        User $user,
        ProjectParticipant $initiator,
        array $payload,
    ): ReportOperation {
        $this->access->assertCanCreateReport($initiator);

        $expenseItem = ProjectExpenseItem::query()
            ->where('project_id', $project->id)
            ->whereKey((int) $payload['expense_item_id'])
            ->where('is_active', true)
            ->whereNull('deleted_at')
            ->first();

        if (! $expenseItem) {
            throw ValidationException::withMessages(['expense_item_id' => ['Статья расходов не найдена или неактивна.']]);
        }

        $customer = $this->participantResolver->requireCustomerParticipant($project);
        $customerCpId = (int) $customer->counterparty_id;

        $recipientPp = $this->participantResolver->resolveRecipientParticipant(
            $project,
            (int) $project->company_id,
            (int) $payload['recipient_counterparty_id'],
            $customerCpId,
        );

        return DB::transaction(function () use (
            $project,
            $user,
            $initiator,
            $payload,
            $expenseItem,
            $customer,
            $recipientPp,
        ): ReportOperation {
            $report = ReportOperation::query()->create([
                'operation_number'                   => null,
                'company_id'                         => (int) $project->company_id,
                'project_id'                         => $project->id,
                'initiator_project_participant_id'   => $initiator->id,
                'recipient_counterparty_id'          => (int) $payload['recipient_counterparty_id'],
                'recipient_project_participant_id'   => $recipientPp->id,
                'customer_project_participant_id'    => $customer->id,
                'expense_item_id'                    => $expenseItem->id,
                'operation_date'                     => (string) $payload['operation_date'],
                'operation_status'                   => OperationStatus::CREATED,
                'recipient_amount'                   => '0.00',
                'customer_base_amount'               => '0.00',
                'markup_amount'                      => '0.00',
                'customer_total_amount'              => '0.00',
                'profit_amount'                      => '0.00',
                'comment'                            => $payload['comment'] ?? null,
                'created_by_user_id'                 => $user->id,
                'updated_by_user_id'                 => $user->id,
            ]);

            $this->replaceLines($report, $payload['lines']);
            $this->recalculateTotals($report, $expenseItem);
            $this->numberService->assignReportNumber($report);

            return $report->fresh()->load(['lines', 'initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project']);
        });
    }

    /**
     * @param  array{expense_item_id?:int,recipient_counterparty_id?:int,operation_date?:string,comment?:string|null,lines?:list<array<string,mixed>>}  $payload
     */
    public function updateReport(
        Project $project,
        ReportOperation $report,
        ProjectParticipant $actor,
        User $user,
        array $payload,
    ): ReportOperation {
        $this->assertSameProject($project, $report);
        $this->access->assertCanEditReport($report, $actor);

        return DB::transaction(function () use ($project, $report, $user, $payload): ReportOperation {
            $fresh = ReportOperation::query()->whereKey($report->id)->lockForUpdate()->firstOrFail();

            if (isset($payload['recipient_counterparty_id'])) {
                $customer = $this->participantResolver->requireCustomerParticipant($project);
                $recipientPp = $this->participantResolver->resolveRecipientParticipant(
                    $project,
                    (int) $project->company_id,
                    (int) $payload['recipient_counterparty_id'],
                    (int) $customer->counterparty_id,
                );
                $fresh->update([
                    'recipient_counterparty_id'        => (int) $payload['recipient_counterparty_id'],
                    'recipient_project_participant_id' => $recipientPp->id,
                ]);
            }

            if (isset($payload['expense_item_id'])) {
                $ei = ProjectExpenseItem::query()
                    ->where('project_id', $project->id)
                    ->whereKey((int) $payload['expense_item_id'])
                    ->where('is_active', true)
                    ->whereNull('deleted_at')
                    ->firstOrFail();
                $fresh->update(['expense_item_id' => $ei->id]);
            }

            if (isset($payload['operation_date'])) {
                $fresh->update(['operation_date' => (string) $payload['operation_date']]);
            }

            if (array_key_exists('comment', $payload)) {
                $fresh->update(['comment' => $payload['comment']]);
            }

            if (isset($payload['lines'])) {
                $this->replaceLines($fresh, $payload['lines']);
            }

            $fresh->refresh();
            $expenseItem = ProjectExpenseItem::query()->whereKey($fresh->expense_item_id)->firstOrFail();
            $this->recalculateTotals($fresh, $expenseItem);
            $fresh->update(['updated_by_user_id' => $user->id]);

            return $fresh->fresh()->load(['lines', 'initiator.counterparty.user', 'recipientParticipant.counterparty.user', 'customerParticipant.counterparty.user', 'project']);
        });
    }

    /**
     * @param  list<array<string,mixed>>  $lines
     */
    private function replaceLines(ReportOperation $report, array $lines): void
    {
        ReportOperationLine::query()->where('report_operation_id', $report->id)->delete();

        $order = 0;
        foreach ($lines as $row) {
            ReportOperationLine::query()->create([
                'report_operation_id'     => $report->id,
                'source_type'             => ReportLineSourceType::from((string) $row['source_type']),
                'price_list_id'           => $row['price_list_id'] ?? null,
                'price_list_group_id'     => $row['price_list_group_id'] ?? null,
                'price_list_position_id'  => $row['price_list_position_id'] ?? null,
                'name'                    => (string) $row['name'],
                'unit_id'                 => $row['unit_id'] ?? null,
                'unit_name'               => (string) $row['unit_name'],
                'unit_short_name'         => (string) $row['unit_short_name'],
                'quantity'                => (string) $row['quantity'],
                'recipient_unit_price'    => (string) $row['recipient_unit_price'],
                'customer_unit_price'     => (string) $row['customer_unit_price'],
                'recipient_total'         => (string) $row['recipient_total'],
                'customer_total'          => (string) $row['customer_total'],
                'sort_order'              => $order++,
            ]);
        }
    }

    private function recalculateTotals(ReportOperation $report, ProjectExpenseItem $expenseItem): void
    {
        $report->load('lines');
        $recipientSum = '0.00';
        $customerSum = '0.00';
        foreach ($report->lines as $line) {
            $recipientSum = $this->addDecimalStrings($recipientSum, (string) $line->recipient_total);
            $customerSum = $this->addDecimalStrings($customerSum, (string) $line->customer_total);
        }

        $markup = '0.00';
        if ($expenseItem->markup_enabled) {
            $pct = (string) ($expenseItem->markup_percent ?? '0');
            $markup = $this->mulPercent($customerSum, $pct);
        }

        $customerTotal = $this->addDecimalStrings($customerSum, $markup);
        $profit = $this->subDecimalStrings($customerSum, $recipientSum);

        if ($this->compareDecimal($profit, '0.00') < 0) {
            throw ValidationException::withMessages([
                'profit_amount' => ['Отрицательная прибыль запрещена (MVP).'],
            ]);
        }

        $report->update([
            'recipient_amount'      => $recipientSum,
            'customer_base_amount'  => $customerSum,
            'markup_amount'         => $markup,
            'customer_total_amount' => $customerTotal,
            'profit_amount'         => $profit,
        ]);
    }

    private function assertSameProject(Project $project, ReportOperation $report): void
    {
        if ((int) $report->project_id !== (int) $project->id) {
            throw ValidationException::withMessages(['project' => ['Отчёт относится к другому проекту.']]);
        }
    }

    private function addDecimalStrings(string $a, string $b): string
    {
        $ca = $this->toCents($a);
        $cb = $this->toCents($b);

        return $this->fromCents($ca + $cb);
    }

    private function subDecimalStrings(string $a, string $b): string
    {
        return $this->fromCents($this->toCents($a) - $this->toCents($b));
    }

    private function mulPercent(string $amount, string $percent): string
    {
        $cents = $this->toCents($amount);
        $p = (float) $percent;
        $raw = (int) round($cents * $p / 100.0);

        return $this->fromCents($raw);
    }

    private function compareDecimal(string $a, string $b): int
    {
        return $this->toCents($a) <=> $this->toCents($b);
    }

    private function toCents(string $amount): int
    {
        $value = trim($amount);
        $negative = str_starts_with($value, '-');
        if ($negative) {
            $value = substr($value, 1);
        }
        if (! preg_match('/^\d+(\.\d{1,2})?$/', $value)) {
            throw ValidationException::withMessages(['amount' => ['Некорректная сумма.']]);
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
