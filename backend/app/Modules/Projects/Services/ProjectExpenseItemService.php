<?php

namespace App\Modules\Projects\Services;

use App\Models\User;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Projects\Models\ProjectExpenseItem;
use App\Modules\Projects\Models\ProjectExpenseItemMarkupShare;
use App\Modules\Projects\Models\ProjectExpenseItemProfitShare;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * ТЗ-10A: CRUD статей расходов проекта (без финансов REPORT).
 */
final class ProjectExpenseItemService
{
    public function __construct(
        private readonly ProjectExpenseItemValidationService $validation,
    ) {}

    /** @return list<array<string, mixed>> */
    public function listActiveForProject(int $projectId): array
    {
        return ProjectExpenseItem::query()
            ->where('project_id', $projectId)
            ->where('is_active', true)
            ->whereNull('deleted_at')
            ->withCount(['profitShares', 'markupShares'])
            ->orderBy('name')
            ->get()
            ->map(fn (ProjectExpenseItem $item) => $this->toListPayload($item))
            ->values()
            ->all();
    }

    public function findActiveForProject(int $projectId, int $expenseItemId): ?ProjectExpenseItem
    {
        return ProjectExpenseItem::query()
            ->where('project_id', $projectId)
            ->whereKey($expenseItemId)
            ->where('is_active', true)
            ->whereNull('deleted_at')
            ->first();
    }

    /**
     * @param  array<int, array{counterparty_id: int|string, percent: mixed}>  $profitShares
     * @param  array<int, array{counterparty_id: int|string, percent: mixed}>  $markupShares
     */
    public function create(
        User $user,
        int $companyId,
        int $projectId,
        string $name,
        array $profitShares,
        bool $markupEnabled,
        mixed $markupPercent,
        array $markupShares,
    ): ProjectExpenseItem {
        $this->validation->validate($companyId, $profitShares, $markupEnabled, $markupPercent, $markupShares);

        return DB::transaction(function () use ($user, $projectId, $name, $profitShares, $markupEnabled, $markupPercent, $markupShares): ProjectExpenseItem {
            $item = new ProjectExpenseItem([
                'project_id' => $projectId,
                'name' => $name,
                'markup_enabled' => $markupEnabled,
                'markup_percent' => $markupEnabled ? $this->validation->normalizeMarkupPercentValue($markupPercent) : null,
                'is_active' => true,
                'created_by_user_id' => (int) $user->id,
                'updated_by_user_id' => (int) $user->id,
            ]);
            $item->save();

            $this->replaceProfitShares($item, $profitShares);
            if ($markupEnabled) {
                $this->replaceMarkupShares($item, $markupShares);
            }

            return $item->fresh(['profitShares.counterparty', 'markupShares.counterparty']);
        });
    }

    /**
     * @param  array<int, array{counterparty_id: int|string, percent: mixed}>  $profitShares
     * @param  array<int, array{counterparty_id: int|string, percent: mixed}>  $markupShares
     */
    public function updateItem(
        User $user,
        int $companyId,
        ProjectExpenseItem $item,
        string $name,
        array $profitShares,
        bool $markupEnabled,
        mixed $markupPercent,
        array $markupShares,
    ): ProjectExpenseItem {
        if (! $item->is_active || $item->trashed()) {
            throw ValidationException::withMessages(['expense_item' => ['Статья недоступна для изменения.']]);
        }

        $this->validation->validate($companyId, $profitShares, $markupEnabled, $markupPercent, $markupShares);

        return DB::transaction(function () use ($user, $item, $name, $profitShares, $markupEnabled, $markupPercent, $markupShares): ProjectExpenseItem {
            $item->update([
                'name' => $name,
                'markup_enabled' => $markupEnabled,
                'markup_percent' => $markupEnabled ? $this->validation->normalizeMarkupPercentValue($markupPercent) : null,
                'updated_by_user_id' => (int) $user->id,
            ]);

            $item->profitShares()->delete();
            $item->markupShares()->delete();

            $this->replaceProfitShares($item, $profitShares);
            if ($markupEnabled) {
                $this->replaceMarkupShares($item, $markupShares);
            }

            return $item->fresh(['profitShares.counterparty', 'markupShares.counterparty']);
        });
    }

    public function softDelete(ProjectExpenseItem $item, User $user): void
    {
        if (! $item->is_active || $item->trashed()) {
            return;
        }

        $item->update([
            'is_active' => false,
            'updated_by_user_id' => (int) $user->id,
        ]);
        $item->delete();
    }

    /** @return array<string, mixed> */
    public function toDetailPayload(ProjectExpenseItem $item): array
    {
        $item->loadMissing(['profitShares.counterparty', 'markupShares.counterparty']);

        return [
            'id' => (int) $item->id,
            'project_id' => (int) $item->project_id,
            'name' => (string) $item->name,
            'markup_enabled' => (bool) $item->markup_enabled,
            'markup_percent' => $item->markup_percent !== null
                ? number_format((float) $item->markup_percent, 2, '.', '')
                : null,
            'is_active' => (bool) $item->is_active,
            'profit_shares' => $item->profitShares->map(fn (ProjectExpenseItemProfitShare $s) => [
                'counterparty_id' => (int) $s->counterparty_id,
                'counterparty_name' => $this->counterpartyDisplay($s->counterparty),
                'percent' => number_format((float) $s->percent, 2, '.', ''),
            ])->values()->all(),
            'markup_shares' => $item->markupShares->map(fn (ProjectExpenseItemMarkupShare $s) => [
                'counterparty_id' => (int) $s->counterparty_id,
                'counterparty_name' => $this->counterpartyDisplay($s->counterparty),
                'percent' => number_format((float) $s->percent, 2, '.', ''),
            ])->values()->all(),
        ];
    }

    /** @return array<string, mixed> */
    private function toListPayload(ProjectExpenseItem $item): array
    {
        return [
            'id' => (int) $item->id,
            'project_id' => (int) $item->project_id,
            'name' => (string) $item->name,
            'markup_enabled' => (bool) $item->markup_enabled,
            'markup_percent' => $item->markup_percent !== null
                ? number_format((float) $item->markup_percent, 2, '.', '')
                : null,
            'is_active' => (bool) $item->is_active,
            'profit_recipients_count' => (int) $item->profit_shares_count,
            'markup_recipients_count' => $item->markup_enabled
                ? (int) $item->markup_shares_count
                : 0,
        ];
    }

    private function counterpartyDisplay(?Counterparty $c): string
    {
        if (! $c) {
            return '';
        }
        $name = trim((string) ($c->full_name ?? ''));
        if ($name !== '') {
            return $name;
        }
        $email = trim((string) ($c->email ?? ''));
        if ($email !== '') {
            return $email;
        }

        return 'Контрагент #'.$c->id;
    }

    /**
     * @param  array<int, array{counterparty_id: int|string, percent: mixed}>  $rows
     */
    private function replaceProfitShares(ProjectExpenseItem $item, array $rows): void
    {
        foreach ($rows as $row) {
            ProjectExpenseItemProfitShare::query()->create([
                'expense_item_id' => $item->id,
                'counterparty_id' => (int) $row['counterparty_id'],
                'percent' => $this->validation->normalizePercentForShare($row['percent'] ?? null),
            ]);
        }
    }

    /**
     * @param  array<int, array{counterparty_id: int|string, percent: mixed}>  $rows
     */
    private function replaceMarkupShares(ProjectExpenseItem $item, array $rows): void
    {
        foreach ($rows as $row) {
            ProjectExpenseItemMarkupShare::query()->create([
                'expense_item_id' => $item->id,
                'counterparty_id' => (int) $row['counterparty_id'],
                'percent' => $this->validation->normalizePercentForShare($row['percent'] ?? null),
            ]);
        }
    }
}
