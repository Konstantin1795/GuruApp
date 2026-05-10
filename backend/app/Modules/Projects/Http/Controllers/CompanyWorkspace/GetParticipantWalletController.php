<?php

namespace App\Modules\Projects\Http\Controllers\CompanyWorkspace;

use App\Modules\Projects\Http\Resources\ProjectParticipantWalletResource;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Services\ProjectVisibilityService;
use App\Modules\Projects\Services\WalletService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\Request;

final class GetParticipantWalletController
{
    public function __invoke(
        Request $request,
        WalletService $walletService,
        ProjectVisibilityService $visibility,
        int $companyId,
        int $projectId,
        int $participantId,
    ) {
        $project = $visibility->assertCanAccessCompanyProject(
            (int) $request->user()->id,
            $companyId,
            $projectId,
        );

        $participant = ProjectParticipant::query()
            ->where('id', $participantId)
            ->where('project_id', $project->id)
            ->firstOrFail();

        // Ensure wallet exists (idempotent — creates only if missing)
        $wallet = $walletService->ensureWallet($participant);

        return ApiResponse::ok([
            'wallet' => (new ProjectParticipantWalletResource($wallet))->resolve(),
        ]);
    }
}
