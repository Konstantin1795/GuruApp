<?php

namespace App\Modules\Companies\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class CreateCounterpartyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'company_role_code' => ['required', 'string', 'exists:company_roles,code'],
            'full_name' => ['required', 'string', 'max:255'],
            'user_id' => ['nullable', 'integer', 'exists:users,id'],
            'email' => ['required', 'string', 'email', 'max:255'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}

