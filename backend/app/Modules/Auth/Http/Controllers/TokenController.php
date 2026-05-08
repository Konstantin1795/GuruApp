<?php

namespace App\Modules\Auth\Http\Controllers;

use App\Models\User;
use App\Modules\Auth\Http\Resources\UserResource;
use App\Modules\Companies\Models\Counterparty;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use App\Modules\Workspaces\Services\WorkspaceResolver;

final class TokenController
{
    public function issue(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:255'],
        ]);

        /** @var User|null $user */
        $user = User::query()->where('email', $data['email'])->first();
        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials.'],
            ]);
        }

        $deviceName = $data['device_name'] ?? 'api';
        $token = $user->createToken($deviceName);

        return ApiResponse::ok([
            'user' => (new UserResource($user))->resolve(),
            'token' => $token->plainTextToken,
        ], status: 201);
    }

    public function me(Request $request)
    {
        $user = $request->user();
        $userId = (int) $user->id;

        $companyRoles = Counterparty::query()
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->pluck('company_role_code')
            ->unique()
            ->values()
            ->all();

        $availableWorkspaces = app(WorkspaceResolver::class)->resolveForUserId($userId);

        return ApiResponse::ok([
            'user' => (new UserResource($user))->resolve(),
            'company_roles' => $companyRoles,
            'available_workspaces' => $availableWorkspaces,
        ]);
    }
}

