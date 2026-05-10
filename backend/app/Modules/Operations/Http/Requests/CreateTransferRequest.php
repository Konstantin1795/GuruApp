<?php

namespace App\Modules\Operations\Http\Requests;

use App\Modules\Operations\Enums\TransferTargetType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

final class CreateTransferRequest extends FormRequest
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
            'transfer_target_type' => [
                'required',
                'string',
                Rule::in(array_map(static fn (TransferTargetType $t) => $t->value, TransferTargetType::cases())),
            ],
            'receiver_project_participant_id' => ['sometimes', 'integer', 'min:1'],
            'receiver_counterparty_id'        => ['sometimes', 'integer', 'min:1'],
            'amount'                          => ['required', 'string', 'regex:/^(?!0+(?:\.0{1,2})?$)\d+(?:\.\d{1,2})?$/'],
            'comment'                         => ['nullable', 'string', 'max:2000'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $v): void {
            $type = (string) $this->input('transfer_target_type');

            if ($type === TransferTargetType::ACCOUNTABLE_BALANCE->value) {
                if (! $this->filled('receiver_project_participant_id')) {
                    $v->errors()->add('receiver_project_participant_id', 'Укажите получателя — участника проекта.');
                }
                if ($this->filled('receiver_counterparty_id')) {
                    $v->errors()->add('receiver_counterparty_id', 'Для подотчётного перевода не используйте counterparty_id.');
                }
            } elseif ($type === TransferTargetType::PERSONAL_BALANCE->value) {
                if (! $this->filled('receiver_counterparty_id')) {
                    $v->errors()->add('receiver_counterparty_id', 'Укажите контрагента компании.');
                }
                if ($this->filled('receiver_project_participant_id')) {
                    $v->errors()->add('receiver_project_participant_id', 'Для расчётного перевода не используйте project_participant_id.');
                }
            }
        });
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
