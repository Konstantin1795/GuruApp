<?php

namespace App\Modules\Projects\Http\Requests;

use App\Modules\Dictionaries\Enums\ProjectRoleCode;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class UpdateProjectParticipantRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string,mixed>
     */
    public function rules(): array
    {
        return [
            'role' => [
                'required',
                'string',
                Rule::in([
                    ProjectRoleCode::PARTNER->value,
                    ProjectRoleCode::SUPERVISOR->value,
                    ProjectRoleCode::EMPLOYEE->value,
                ]),
            ],
        ];
    }

    /**
     * @return array<string,string>
     */
    public function messages(): array
    {
        return [
            'role.in' => 'Allowed roles: PARTNER, SUPERVISOR, EMPLOYEE.',
        ];
    }
}
