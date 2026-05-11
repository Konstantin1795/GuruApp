<?php

namespace App\Modules\Operations\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class CreateIncomeRequest extends FormRequest
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
            'amount'  => ['required', 'string', 'regex:/^(?!0+(?:\.0{1,2})?$)\d+(?:\.\d{1,2})?$/'],
            'comment' => ['nullable', 'string', 'max:2000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'amount.regex' => 'Сумма должна быть больше 0, до 2 знаков после запятой.',
        ];
    }
}
