<?php

namespace App\Modules\Companies\Http\Controllers\CompanyWorkspace;

use App\Modules\Companies\Http\Resources\CounterpartyResource;
use App\Modules\Companies\Models\Counterparty;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\PaginatedResourceResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

final class ListCounterpartiesController
{
    public function __invoke(Request $request, int $companyId)
    {
        $p = Pagination::fromRequest($request);
        $q = trim((string) $request->query('q', ''));
        $role = trim((string) $request->query('company_role', ''));
        $qLike = $q === '' ? null : '%'.Str::lower($q).'%';

        $query = Counterparty::query()
            ->where('company_id', $companyId)
            ->with('user')
            ->orderByDesc('id');

        if ($role !== '') {
            $query->where('company_role_code', $role);
        }

        if ($q !== '') {
            $query->where(function ($sub) use ($q, $qLike) {
                if (is_numeric($q)) {
                    $sub->orWhere('counterparties.id', (int) $q)
                        ->orWhere('counterparties.user_id', (int) $q);
                }

                $sub->orWhereRaw('LOWER(counterparties.company_role_code) LIKE ?', [$qLike])
                    ->orWhereRaw('LOWER(counterparties.email) LIKE ?', [$qLike])
                    ->orWhereRaw('LOWER(counterparties.full_name) LIKE ?', [$qLike])
                    ->orWhereHas('user', function ($uq) use ($qLike) {
                        $uq->whereRaw('LOWER(email) LIKE ?', [$qLike])
                            ->orWhereRaw('LOWER(name) LIKE ?', [$qLike]);
                    });
            });
        }

        $paginator = $query->paginate(
            perPage: $p['per_page'],
            page: $p['page'],
        );

        $collection = CounterpartyResource::collection($paginator->items());

        return ApiResponse::ok(PaginatedResourceResponse::fromPaginator($collection, $paginator));
    }
}

