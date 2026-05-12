<?php

namespace App\Modules\Projects\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class AttachProjectPriceListsRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'price_list_ids' => ['required', 'array', 'min:1'],
            'price_list_ids.*' => ['integer', 'min:1'],
        ];
    }
}
