<?php

namespace App\Modules\Projects\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

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
        return [
            'project' => [
                'id' => (int) ($this->project_id ?? $this['project_id']),
                'name' => (string) ($this->project_name ?? $this['project_name']),
                'progress_percent' => (int) ($this->progress_percent ?? $this['progress_percent']),
                'is_active' => (bool) ($this->is_active ?? $this['is_active']),
            ],
            'company' => [
                'id' => (int) ($this->company_id ?? $this['company_id']),
                'name' => (string) ($this->company_name ?? $this['company_name']),
            ],
        ];
    }
}

