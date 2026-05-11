<?php

namespace App\Modules\Projects\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class StoreProjectExpenseItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'profit_shares' => ['required', 'array', 'min:1'],
            'profit_shares.*.counterparty_id' => ['required', 'integer', 'min:1'],
            'profit_shares.*.percent' => ['required'],
            'markup_enabled' => ['sometimes', 'boolean'],
            'markup_percent' => ['nullable', 'required_if:markup_enabled,true'],
            'markup_shares' => ['nullable', 'required_if:markup_enabled,true', 'array', 'min:1'],
            'markup_shares.*.counterparty_id' => ['required_if:markup_enabled,true', 'integer', 'min:1'],
            'markup_shares.*.percent' => ['required_if:markup_enabled,true'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'markup_enabled' => $this->boolean('markup_enabled'),
        ]);
    }
}
