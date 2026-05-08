<?php

namespace App\Policies;

use App\Models\User;
use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Enums\CompanyRoleCode;

final class CompanyPolicy
{
    /**
     * Company Workspace access (OWNER / PARTNER only).
     */
    public function accessWorkspace(User $user, Company $company): bool
    {
        return Counterparty::query()
            ->where('company_id', $company->id)
            ->where('user_id', $user->id)
            ->whereIn('company_role_code', [
                CompanyRoleCode::OWNER->value,
                CompanyRoleCode::PARTNER->value,
            ])
            ->where('is_active', true)
            ->exists();
    }
}

