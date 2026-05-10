<?php

namespace App\Modules\Operations\Services;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Models\ProjectParticipant;

/**
 * ТЗ-05.3: из личного кабинета перевод инициирует только сотрудник 1-го порядка (роль в проекте EMPLOYEE).
 */
final class PersonalWorkspaceTransferGuard
{
    public function assertCanInitiateTransfer(ProjectParticipant $initiator): void
    {
        if (strtolower((string) $initiator->level) !== 'first') {
            abort(403, 'Создание перевода из личного кабинета доступно только участникам первого порядка.');
        }

        if ($initiator->project_role_code !== ProjectRoleCode::EMPLOYEE->value) {
            abort(403, 'Создание перевода из личного кабинета доступно только сотрудникам проекта.');
        }
    }
}
