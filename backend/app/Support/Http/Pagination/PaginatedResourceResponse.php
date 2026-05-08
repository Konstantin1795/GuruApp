<?php

namespace App\Support\Http\Pagination;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\Resources\Json\ResourceCollection;

final class PaginatedResourceResponse
{
    /**
     * @return array{items:array<int,mixed>, pagination:array<string,mixed>}
     */
    public static function fromPaginator(ResourceCollection $collection, LengthAwarePaginator $paginator): array
    {
        return [
            'items' => $collection->resolve(),
            'pagination' => [
                'page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
            ],
        ];
    }
}

