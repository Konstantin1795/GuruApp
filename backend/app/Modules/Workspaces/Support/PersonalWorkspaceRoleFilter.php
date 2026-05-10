<?php

declare(strict_types=1);

namespace App\Modules\Workspaces\Support;

use App\Modules\Dictionaries\Enums\CompanyRoleCode;

final class PersonalWorkspaceRoleFilter
{
    /**
     * @return list<string>
     */
    public static function fromQuery(?string $workspaceRole): array
    {
        return match ($workspaceRole) {
            'customer' => [CompanyRoleCode::CUSTOMER->value],
            'performer' => [
                CompanyRoleCode::EMPLOYEE->value,
                CompanyRoleCode::SUPPLIER->value,
                CompanyRoleCode::CONTRACTOR->value,
            ],
            default => [
                CompanyRoleCode::CUSTOMER->value,
                CompanyRoleCode::EMPLOYEE->value,
                CompanyRoleCode::SUPPLIER->value,
                CompanyRoleCode::CONTRACTOR->value,
            ],
        };
    }
}
