<?php

namespace App\Modules\Auth\Http\Controllers;

use App\Models\User;
use App\Modules\Auth\Http\Requests\RegisterRequest;
use App\Modules\Auth\Http\Resources\UserResource;
use App\Modules\Companies\Services\UserCounterpartyLinkingService;
use App\Support\Http\ApiResponse;
use Illuminate\Support\Facades\Hash;

final class RegisterController
{
    public function __invoke(RegisterRequest $request, UserCounterpartyLinkingService $linkingService)
    {
        $data = $request->validated();

        $user = User::query()->create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
        ]);

        $linkingService->linkByEmail($user);

        $deviceName = $data['device_name'] ?? 'api';
        $token = $user->createToken($deviceName);

        return ApiResponse::ok([
            'user' => (new UserResource($user))->resolve(),
            'token' => $token->plainTextToken,
        ], status: 201);
    }
}

