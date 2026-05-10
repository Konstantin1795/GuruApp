<?php

namespace App\Modules\Projects\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class CreateProjectRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:255'],
            'customer_counterparty_id' => ['nullable', 'integer', 'exists:counterparties,id'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}

