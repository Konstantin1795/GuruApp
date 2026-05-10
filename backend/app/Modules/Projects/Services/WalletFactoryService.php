<?php

namespace App\Modules\Projects\Services;

use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Models\ProjectParticipantWallet;

/**
 * Creates and initialises a wallet for a ProjectParticipant.
 * Every balance field starts at 0.00.
 * Idempotent: if the wallet already exists it is returned as-is.
 */
final class WalletFactoryService
{
    public function createForParticipant(ProjectParticipant $participant): ProjectParticipantWallet
    {
        /** @var ProjectParticipantWallet $wallet */
        $wallet = ProjectParticipantWallet::query()->firstOrCreate(
            ['project_participant_id' => $participant->id],
            [
                'personal_balance'     => '0.00',
                'personal_earned'      => '0.00',
                'personal_received'    => '0.00',
                'accountable_balance'  => '0.00',
                'accountable_received' => '0.00',
                'accountable_spent'    => '0.00',
            ],
        );

        return $wallet;
    }
}
