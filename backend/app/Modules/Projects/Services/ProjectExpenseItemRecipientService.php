<?php

namespace App\Modules\Projects\Services;

use App\Modules\Companies\Models\Counterparty;
use Illuminate\Support\Collection;

/**
 * ТЗ-10A: списки контрагентов компании для выбора получателей долей (MVP — без вкладок).
 */
final class ProjectExpenseItemRecipientService
{
    /**
     * Активные контрагенты компании с опциональным поиском по ФИО/email.
     *
     * @return Collection<int, array{id: int, counterparty_name: string}>
     */
    public function listCompanyCounterparties(int $companyId, ?string $search): Collection
    {
        $search = $search !== null ? trim($search) : '';

        $base = Counterparty::query()
            ->where('company_id', $companyId)
            ->where('is_active', true);

        if ($search !== '') {
            $term = '%'.mb_strtolower($search, 'UTF-8').'%';
            $base->where(function ($q) use ($term): void {
                $q->whereRaw('LOWER(COALESCE(full_name, \'\')) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(COALESCE(email, \'\')) LIKE ?', [$term]);
            });
        }

        return $base
            ->orderByRaw('COALESCE(NULLIF(TRIM(full_name), \'\'), email, \'\')')
            ->limit(500)
            ->get()
            ->map(fn (Counterparty $c) => [
                'id' => (int) $c->id,
                'counterparty_name' => $this->counterpartyLabel($c),
            ])
            ->values();
    }

    private function counterpartyLabel(Counterparty $c): string
    {
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
}
