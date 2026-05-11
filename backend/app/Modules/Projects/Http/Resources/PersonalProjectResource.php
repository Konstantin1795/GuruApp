<?php

namespace App\Modules\Projects\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Arr;

/**
 * Personal Workspace project DTO.
 *
 * Expected input fields:
 * - project_id
 * - project_name
 * - progress_percent
 * - is_active
 * - company_id
 * - company_name
 */
final class PersonalProjectResource extends JsonResource
{
    /**
     * @return array<string,mixed>
     */
    public function toArray(Request $request): array
    {
        $raw = $this->resource;
        if (is_object($raw) && ! is_array($raw)) {
            $decoded = json_decode(json_encode($raw), true);
            $raw = is_array($decoded) ? $decoded : [];
        }
        if (! is_array($raw)) {
            $raw = [];
        }

        $dec = static function (mixed $v, string $fallback = '0.00'): string {
            if ($v === null || $v === '') {
                return $fallback;
            }
            if (is_string($v)) {
                return $v;
            }
            if (is_numeric($v)) {
                return number_format((float) $v, 2, '.', '');
            }

            return $fallback;
        };

        $companyName = (string) Arr::get($raw, 'company_name', '');

        return [
            'project' => [
                'id' => (int) Arr::get($raw, 'project_id'),
                'name' => (string) Arr::get($raw, 'project_name'),
                'progress_percent' => (int) Arr::get($raw, 'progress_percent'),
                'is_active' => (bool) Arr::get($raw, 'is_active'),
            ],
            'company' => [
                'id' => (int) Arr::get($raw, 'company_id'),
                'name' => $companyName,
            ],
            'my_wallet' => [
                'personal_balance' => $dec(Arr::get($raw, 'wallet_personal_balance')),
                'personal_received' => $dec(Arr::get($raw, 'wallet_personal_received')),
                'personal_earned' => $dec(Arr::get($raw, 'wallet_personal_earned')),
                'accountable_spent' => $dec(Arr::get($raw, 'wallet_accountable_spent')),
                'accountable_balance' => $dec(Arr::get($raw, 'wallet_accountable_balance')),
                'income_received_total' => $dec(Arr::get($raw, 'income_received_total')),
            ],
            'my_participation' => [
                'level' => (string) Arr::get($raw, 'participant_level', ''),
                'project_role_code' => (string) Arr::get($raw, 'participant_project_role_code', ''),
            ],
        ];
    }
}

