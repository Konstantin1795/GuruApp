<?php

namespace App\Modules\Auth\Http\Controllers;

use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class LogoutController
{
    public function __invoke(Request $request)
    {
        $token = $request->user()?->currentAccessToken();
        if ($token) {
            $token->delete();
        }

        return ApiResponse::ok([
            'logged_out' => true,
        ]);
    }
}

