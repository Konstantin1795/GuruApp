<?php

namespace App\Modules\Workspaces\Http\Middleware;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class EnsurePersonalWorkspaceAccess
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if (! $user) {
            abort(401, 'Unauthenticated.');
        }

        $hasAccess = Counterparty::query()
            ->where('user_id', (int) $user->id)
            ->whereIn('company_role_code', [
                CompanyRoleCode::EMPLOYEE->value,
                CompanyRoleCode::CONTRACTOR->value,
                CompanyRoleCode::SUPPLIER->value,
                CompanyRoleCode::CUSTOMER->value,
            ])
            ->where('is_active', true)
            ->exists();

        if (! $hasAccess) {
            abort(403, 'Forbidden.');
        }

        return $next($request);
    }
}

