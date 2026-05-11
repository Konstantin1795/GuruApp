<?php

namespace App\Modules\Operations\Services;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Validation\ValidationException;

/**
 * ТЗ-06 MVP: ровно один активный PROJECT_HEAD и один активный CUSTOMER в проекте.
 */
final class IncomeProjectParticipantsResolver
{
    /**
     * @return array{0: ProjectParticipant, 1: ProjectParticipant} [head, customer]
     *
     * @throws ValidationException
     */
    public function resolveHeadAndCustomer(Project $project): array
    {
        $heads = ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('is_active', true)
            ->where('project_role_code', ProjectRoleCode::PROJECT_HEAD->value)
            ->orderBy('id')
            ->get();

        if ($heads->isEmpty()) {
            throw ValidationException::withMessages([
                'project' => ['В проекте не найден активный руководитель проекта (PROJECT_HEAD). Нельзя создать поступление.'],
            ]);
        }

        if ($heads->count() > 1) {
            throw ValidationException::withMessages([
                'project' => ['Ошибка данных: в проекте несколько активных руководителей проекта (PROJECT_HEAD). Обратитесь к администратору.'],
            ]);
        }

        $customers = ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('is_active', true)
            ->where('project_role_code', ProjectRoleCode::CUSTOMER->value)
            ->orderBy('id')
            ->get();

        if ($customers->isEmpty()) {
            throw ValidationException::withMessages([
                'project' => ['В проекте не найден активный заказчик (CUSTOMER). Нельзя создать поступление.'],
            ]);
        }

        if ($customers->count() > 1) {
            throw ValidationException::withMessages([
                'project' => ['Ошибка данных: в проекте несколько активных заказчиков (CUSTOMER). Обратитесь к администратору.'],
            ]);
        }

        /** @var ProjectParticipant $head */
        $head = $heads->first();
        /** @var ProjectParticipant $customer */
        $customer = $customers->first();

        return [$head, $customer];
    }
}
