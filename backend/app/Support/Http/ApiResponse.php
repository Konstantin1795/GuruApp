<?php

namespace App\Support\Http;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Arr;

final class ApiResponse
{
    /**
     * @param array<string,mixed>|null $data
     * @param array<string,mixed> $meta
     */
    public static function ok(?array $data = null, array $meta = [], int $status = 200): JsonResponse
    {
        $requestId = request()?->headers?->get('X-Request-Id');
        $meta = Arr::whereNotNull([
            'request_id' => $requestId,
            ...$meta,
        ]);

        return response()->json([
            'ok' => true,
            'data' => $data ?? (object) [],
            'meta' => (object) $meta,
        ], $status);
    }
}

