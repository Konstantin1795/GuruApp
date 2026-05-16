<?php

namespace App\Modules\Projects\Services;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\IncomeOperation;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Support\Facades\DB;

/**
 * ТЗ-07: агрегаты поступления / расхода / баланса проекта и внутренние метрики.
 */
final class ProjectSummaryMetricsService
{
    public function __construct(
        private readonly WalletService $walletService,
    ) {}

    /**
     * Поступление: сумма INCOME по проекту в статусах с проведёнными и не откатанными дельтами (ТЗ-07 §11.1).
     */
    public function incomeTotalApplied(Project $project): string
    {
        return $this->formatMoney($this->incomeAppliedDecimalSum($project));
    }

    /**
     * Расход по проекту: сумма {@see ReportOperation::$customer_total_amount} по отчётам REPORT,
     * у которых финансовые дельты применены и не откатаны (`wallets_applied_at`, `wallets_reverted_at`).
     */
    public function reportExpenseTotalApplied(Project $project): string
    {
        return $this->formatMoney($this->reportCustomerTotalAppliedDecimalSum($project));
    }

    /**
     * Баланс в карточке «Показатели проекта» (summary): поступление минус расход по отчётам заказчику.
     */
    public function summaryProjectBalanceIncomeMinusExpense(Project $project): string
    {
        $balance = $this->incomeAppliedDecimalSum($project) - $this->reportCustomerTotalAppliedDecimalSum($project);

        return $this->formatMoney($balance);
    }

    /**
     * Баланс проекта = accountable_balance кошелька участника с ролью CUSTOMER (ТЗ-07 §11.3).
     */
    public function customerAccountableBalance(Project $project): string
    {
        $customer = ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('project_role_code', ProjectRoleCode::CUSTOMER->value)
            ->where('is_active', true)
            ->first();

        if ($customer === null) {
            return '0.00';
        }

        $wallet = $this->walletService->ensureWallet($customer);

        return $this->formatMoney($wallet->accountable_balance);
    }

    /**
     * Подотчётный баланс участников без CUSTOMER (ТЗ-07 §16.1).
     */
    public function participantsAccountableBalanceExcludingCustomer(Project $project): string
    {
        $sum = DB::table('project_participants as pp')
            ->join('project_participant_wallets as w', 'w.project_participant_id', '=', 'pp.id')
            ->where('pp.project_id', $project->id)
            ->where('pp.is_active', true)
            ->where('pp.project_role_code', '!=', ProjectRoleCode::CUSTOMER->value)
            ->sum(DB::raw('CAST(w.accountable_balance AS DECIMAL(18,2))'));

        return $this->formatMoney($sum);
    }

    /**
     * Долг контрагентам / переплата — placeholder до REPORT (ТЗ-07 §16.2–16.3).
     */
    public function zeroPlaceholder(): string
    {
        return '0.00';
    }

    private function incomeAppliedDecimalSum(Project $project): float
    {
        $sum = IncomeOperation::query()
            ->where('project_id', $project->id)
            ->whereIn('operation_status', [
                OperationStatus::CUSTOMER_APPROVAL,
                OperationStatus::WAITING_24_HOURS,
                OperationStatus::COMPLETED,
            ])
            ->whereNotNull('wallets_applied_at')
            ->sum(DB::raw('CAST(amount AS DECIMAL(18,2))'));

        return (float) ($sum ?? 0);
    }

    private function reportCustomerTotalAppliedDecimalSum(Project $project): float
    {
        $sum = ReportOperation::query()
            ->where('project_id', $project->id)
            ->whereNotNull('wallets_applied_at')
            ->whereNull('wallets_reverted_at')
            ->sum(DB::raw('CAST(customer_total_amount AS DECIMAL(18,2))'));

        return (float) ($sum ?? 0);
    }

    private function formatMoney(mixed $value): string
    {
        if ($value === null) {
            return '0.00';
        }

        return number_format((float) $value, 2, '.', '');
    }
}
