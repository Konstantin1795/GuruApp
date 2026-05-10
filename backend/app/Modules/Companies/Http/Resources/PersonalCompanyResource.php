<?php

namespace App\Modules\Companies\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Arr;

/**
 * Lightweight DTO-like resource for Personal Workspace.
 *
 * Expected input fields:
 * - company_id
 * - company_name
 * - is_active
 * - company_role_code
 */
final class PersonalCompanyResource extends JsonResource
{
    /**
     * @return array<string,mixed>
     */
    public function toArray(Request $request): array
    {
        $raw = $this->resource;
        // Paginator rows are often stdClass; normalize so Arr::get always resolves keys.
        if (is_object($raw) && ! is_array($raw)) {
            $decoded = json_decode(json_encode($raw), true);
            $raw = is_array($decoded) ? $decoded : [];
        }
        if (! is_array($raw)) {
            $raw = [];
        }

        $name = (string) Arr::get($raw, 'company_name', '');
        if ($name === '') {
            $name = (string) Arr::get($raw, 'name', '');
        }

        return [
            'company' => [
                'id' => (int) Arr::get($raw, 'company_id'),
                'name' => $name,
                'is_active' => (bool) Arr::get($raw, 'is_active'),
            ],
            'company_role' => (string) Arr::get($raw, 'company_role_code'),
            'projects_count' => (int) Arr::get($raw, 'projects_count', 0),
        ];
    }
}

