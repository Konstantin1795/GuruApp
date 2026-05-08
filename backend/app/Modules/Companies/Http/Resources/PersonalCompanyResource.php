<?php

namespace App\Modules\Companies\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

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
        return [
            'company' => [
                'id' => (int) ($this->company_id ?? $this['company_id']),
                'name' => (string) ($this->company_name ?? $this['company_name']),
                'is_active' => (bool) ($this->is_active ?? $this['is_active']),
            ],
            'company_role' => (string) ($this->company_role_code ?? $this['company_role_code']),
        ];
    }
}

