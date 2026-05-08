<?php

namespace App\Modules\Workspaces\Http\Controllers;

use App\Modules\Workspaces\Services\WorkspaceResolver;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class ListWorkspacesController
{
    public function __invoke(Request $request, WorkspaceResolver $resolver)
    {
        $userId = (int) $request->user()->id;

        return ApiResponse::ok($resolver->resolveForUserId($userId));
    }
}

