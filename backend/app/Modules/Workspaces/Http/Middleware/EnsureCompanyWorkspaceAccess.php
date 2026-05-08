<?php

namespace App\Modules\Workspaces\Http\Middleware;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class EnsureCompanyWorkspaceAccess
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if (! $user) {
            abort(401, 'Unauthenticated.');
        }

        $companyId = $request->route('companyId');
        if (! $companyId) {
            abort(400, 'companyId is required.');
        }

        $hasAccess = Counterparty::query()
            ->where('company_id', (int) $companyId)
            ->where('user_id', (int) $user->id)
            ->whereIn('company_role_code', [
                CompanyRoleCode::OWNER->value,
                CompanyRoleCode::PARTNER->value,
            ])
            ->where('is_active', true)
            ->exists();

        if (! $hasAccess) {
            abort(403, 'Forbidden.');
        }

        return $next($request);
    }
}

