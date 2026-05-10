<?php

namespace App\Support\Http\Pagination;

use Illuminate\Http\Request;

final class Pagination
{
    /**
     * @return array{page:int, per_page:int}
     */
    public static function fromRequest(Request $request, int $defaultPerPage = 20, int $maxPerPage = 50): array
    {
        $page = (int) $request->query('page', 1);
        $page = $page < 1 ? 1 : $page;

        $perPage = (int) $request->query('per_page', $defaultPerPage);
        if ($perPage < 1) {
            $perPage = $defaultPerPage;
        }
        if ($perPage > $maxPerPage) {
            $perPage = $maxPerPage;
        }

        return ['page' => $page, 'per_page' => $perPage];
    }
}

