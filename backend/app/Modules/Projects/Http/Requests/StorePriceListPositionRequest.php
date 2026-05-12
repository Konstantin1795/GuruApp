<?php

namespace App\Modules\Projects\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class StorePriceListPositionRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'service_name' => ['required', 'string', 'max:512'],
            'unit_id' => ['required', 'integer', 'min:1'],
            'recipient_unit_price' => ['required', 'string', 'max:32'],
            'customer_unit_price' => ['required', 'string', 'max:32'],
        ];
    }
}
