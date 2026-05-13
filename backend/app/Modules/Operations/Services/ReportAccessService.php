<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Validation\ValidationException;

final class ReportAccessService
{
    /**
     * @throws ValidationException
     */
    public function assertCanCreateReport(ProjectParticipant $actor): void
    {
        if (strtolower((string) $actor->level) !== 'first') {
            throw ValidationException::withMessages([
                'actor' => ['Создавать отчёт может только участник первого порядка.'],
            ]);
        }

        $allowed = [
            ProjectRoleCode::PROJECT_HEAD->value,
            ProjectRoleCode::PARTNER->value,
            ProjectRoleCode::EMPLOYEE->value,
        ];

        if (! in_array($actor->project_role_code, $allowed, true)) {
            throw ValidationException::withMessages([
                'actor' => ['Ваша роль не может создавать отчёт.'],
            ]);
        }
    }

    /**
     * @throws ValidationException
     */
    public function assertCanEditReport(ReportOperation $report, ProjectParticipant $actor): void
    {
        $status = $report->operation_status;
        $editable = [
            OperationStatus::CREATED,
            OperationStatus::SUPERVISOR_APPROVAL,
            OperationStatus::PROJECT_HEAD_APPROVAL,
        ];

        if (! in_array($status, $editable, true)) {
            throw ValidationException::withMessages(['report' => ['Редактирование в этом статусе запрещено.']]);
        }

        if ($status === OperationStatus::PROJECT_HEAD_APPROVAL && $report->wallets_applied_at !== null) {
            throw ValidationException::withMessages(['report' => ['Редактирование после применения финансов запрещено.']]);
        }

        if ($status === OperationStatus::SUPERVISOR_APPROVAL) {
            if ((int) $report->initiator_project_participant_id !== (int) $actor->id
                && $actor->project_role_code !== ProjectRoleCode::PROJECT_HEAD->value) {
                throw ValidationException::withMessages(['actor' => ['Редактирование доступно инициатору или РП.']]);
            }

            return;
        }

        if ($status === OperationStatus::CREATED) {
            if ((int) $report->initiator_project_participant_id !== (int) $actor->id
                && $actor->project_role_code !== ProjectRoleCode::PROJECT_HEAD->value) {
                throw ValidationException::withMessages(['actor' => ['Редактирование доступно инициатору или РП.']]);
            }

            return;
        }

        if ($status === OperationStatus::PROJECT_HEAD_APPROVAL) {
            if ((int) $report->initiator_project_participant_id !== (int) $actor->id
                && $actor->project_role_code !== ProjectRoleCode::PROJECT_HEAD->value) {
                throw ValidationException::withMessages(['actor' => ['Редактирование доступно инициатору или РП.']]);
            }
        }
    }
}
