<?php

namespace App\Modules\Dictionaries\Services;

use App\Modules\Dictionaries\Models\CompanyRole;
use App\Modules\Dictionaries\Models\ProjectRole;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Enums\OperationType;
use Illuminate\Support\Facades\Cache;

/**
 * Cache foundation for stable dictionaries.
 * Do not use this for frequently changing domain data like wallets, projects,
 * counterparties, project participants, or operations.
 */
final class DictionaryCacheService
{
    private const TTL_SECONDS = 3600;

    /**
     * @return array<int,array{code:string,description:string|null}>
     */
    public function companyRoles(): array
    {
        return Cache::remember('guru:dict:company_roles', self::TTL_SECONDS, function () {
            return CompanyRole::query()
                ->orderBy('code')
                ->get(['code', 'description'])
                ->map(fn (CompanyRole $role) => [
                    'code' => $role->code,
                    'description' => $role->description,
                ])
                ->all();
        });
    }

    /**
     * @return array<int,array{code:string,description:string|null}>
     */
    public function projectRoles(): array
    {
        return Cache::remember('guru:dict:project_roles', self::TTL_SECONDS, function () {
            return ProjectRole::query()
                ->orderBy('code')
                ->get(['code', 'description'])
                ->map(fn (ProjectRole $role) => [
                    'code' => $role->code,
                    'description' => $role->description,
                ])
                ->all();
        });
    }

    /**
     * @return array<int,array{code:string}>
     */
    public function operationTypes(): array
    {
        return Cache::remember('guru:dict:operation_types', self::TTL_SECONDS, function () {
            return array_map(
                fn (OperationType $type) => ['code' => $type->value],
                OperationType::cases(),
            );
        });
    }

    /**
     * @return array<int, array{
     *     code: string,
     *     terminal: bool,
     *     is_terminal_by_operation_type: array<string, bool>
     * }>
     */
    public function operationStatuses(): array
    {
        return Cache::remember('guru:dict:operation_statuses:v2', self::TTL_SECONDS, function () {
            return array_map(
                function (OperationStatus $status) {
                    $byType = [];
                    foreach (OperationType::cases() as $type) {
                        $byType[$type->value] = $status->isTerminalForOperationType($type);
                    }

                    return [
                        'code' => $status->value,
                        'terminal' => $status->isTerminal(),
                        'is_terminal_by_operation_type' => $byType,
                    ];
                },
                OperationStatus::cases(),
            );
        });
    }

    public function flush(): void
    {
        Cache::forget('guru:dict:company_roles');
        Cache::forget('guru:dict:project_roles');
        Cache::forget('guru:dict:operation_types');
        Cache::forget('guru:dict:operation_statuses');
        Cache::forget('guru:dict:operation_statuses:v2');
    }
}
