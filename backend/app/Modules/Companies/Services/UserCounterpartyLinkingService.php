<?php

namespace App\Modules\Companies\Services;

use App\Models\User;
use App\Modules\Companies\Models\Counterparty;
use Illuminate\Support\Facades\Log;

/**
 * Links newly registered or returning users to invite-first counterparties by email.
 *
 * Security rules:
 * - normalize emails with trim + lowercase before comparing;
 * - link only counterparties with empty user_id;
 * - never overwrite another user's counterparty link;
 * - idempotent: safe to call after registration, login, and /auth/me.
 */
final class UserCounterpartyLinkingService
{
    /**
     * @return array<int, int> Linked counterparty IDs.
     */
    public function linkByEmail(User $user): array
    {
        $email = $this->normalizeEmail((string) $user->email);
        if ($email === '') {
            return [];
        }

        $counterparties = Counterparty::query()
            ->whereRaw('LOWER(TRIM(email)) = ?', [$email])
            ->where('is_active', true)
            ->get();

        $linkedIds = [];

        foreach ($counterparties as $counterparty) {
            if ($counterparty->user_id === null) {
                $counterparty->update(['user_id' => $user->id]);
                $linkedIds[] = (int) $counterparty->id;
                continue;
            }

            if ((int) $counterparty->user_id === (int) $user->id) {
                $linkedIds[] = (int) $counterparty->id;
                continue;
            }

            Log::warning('Counterparty email link conflict.', [
                'counterparty_id' => $counterparty->id,
                'counterparty_user_id' => $counterparty->user_id,
                'current_user_id' => $user->id,
                'email' => $email,
            ]);
        }

        return $linkedIds;
    }

    private function normalizeEmail(string $email): string
    {
        return mb_strtolower(trim($email));
    }
}
