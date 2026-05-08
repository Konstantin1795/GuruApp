<?php

namespace App\Modules\System\Http\Controllers;

use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class HealthController
{
    public function __invoke(Request $request)
    {
        return ApiResponse::ok([
            'status' => 'ok',
            'app' => 'GURU',
            'env' => config('app.env'),
            'time' => now()->toIso8601String(),
        ]);
    }
}

