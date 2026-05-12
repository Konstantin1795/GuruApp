<?php

namespace App\Modules\Projects\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class PatchPriceListPositionRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'service_name' => ['sometimes', 'string', 'max:512'],
            'unit_id' => ['sometimes', 'integer', 'min:1'],
            'recipient_unit_price' => ['sometimes', 'string', 'max:32'],
            'customer_unit_price' => ['sometimes', 'string', 'max:32'],
        ];
    }
}
