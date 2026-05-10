<?php

namespace App\Modules\Projects\Services;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Projects\Models\ProjectParticipantWallet;
use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class ProjectParticipantService
{
    public function __construct(private readonly WalletFactoryService $walletFactory) {}

    /**
     * Add a participant to a project.
     *
     * @throws ValidationException
     */
    public function add(
        Project $project,
        int $counterpartyId,
        string $roleCode,
        int $companyId,
    ): ProjectParticipant {
        $counterparty = Counterparty::query()
            ->where('id', $counterpartyId)
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->first();

        if (! $counterparty) {
            throw ValidationException::withMessages([
                'counterparty_id' => ['Counterparty not found in this company.'],
            ]);
        }

        $alreadyExists = ProjectParticipant::query()
            ->where('project_id', $project->id)
            ->where('counterparty_id', $counterpartyId)
            ->exists();

        if ($alreadyExists) {
            throw ValidationException::withMessages([
                'counterparty_id' => ['This counterparty is already a participant of this project.'],
            ]);
        }

        return DB::transaction(function () use ($project, $counterpartyId, $roleCode) {
            $participant = ProjectParticipant::query()->create([
                'project_id'        => $project->id,
                'counterparty_id'   => $counterpartyId,
                'project_role_code' => $roleCode,
                'level'             => 'first',
                'is_active'         => true,
            ]);

            $this->walletFactory->createForParticipant($participant);

            return $participant;
        });
    }

    /**
     * @throws ValidationException
     */
    public function updateRole(
        Project $project,
        int $participantId,
        string $newRoleCode,
    ): ProjectParticipant {
        $participant = ProjectParticipant::query()
            ->where('id', $participantId)
            ->where('project_id', $project->id)
            ->firstOrFail();

        $locked = [
            ProjectRoleCode::PROJECT_HEAD->value,
            ProjectRoleCode::CUSTOMER->value,
        ];

        if (in_array($participant->project_role_code, $locked, true)) {
            throw ValidationException::withMessages([
                'role' => ['Роль этого участника нельзя изменить.'],
            ]);
        }

        DB::transaction(function () use ($participant, $newRoleCode): void {
            $participant->update([
                'project_role_code' => $newRoleCode,
            ]);
        });

        $participant->refresh();
        $participant->load(['counterparty.user']);

        return $participant;
    }

    /**
     * @throws ValidationException
     */
    public function remove(
        Project $project,
        int $participantId,
    ): void {
        $participant = ProjectParticipant::query()
            ->where('id', $participantId)
            ->where('project_id', $project->id)
            ->firstOrFail();

        if ($participant->project_role_code === ProjectRoleCode::PROJECT_HEAD->value) {
            throw ValidationException::withMessages([
                'participant' => ['Нельзя удалить руководителя проекта.'],
            ]);
        }

        DB::transaction(function () use ($participant): void {
            $participant->delete();
        });
    }
}
