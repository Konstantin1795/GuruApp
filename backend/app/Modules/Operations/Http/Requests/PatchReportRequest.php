<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Requests;

use App\Modules\Operations\Enums\ReportLineSourceType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class PatchReportRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'expense_item_id' => ['sometimes', 'integer', 'min:1'],
            'recipient_counterparty_id' => ['sometimes', 'integer', 'min:1'],
            'operation_date' => ['sometimes', 'date_format:Y-m-d'],
            'comment' => ['sometimes', 'nullable', 'string', 'max:5000'],
            'lines' => ['sometimes', 'array', 'min:1'],
            'lines.*.source_type' => ['required_with:lines', 'string', Rule::enum(ReportLineSourceType::class)],
            'lines.*.price_list_id' => ['nullable', 'integer', 'min:1'],
            'lines.*.price_list_group_id' => ['nullable', 'integer', 'min:1'],
            'lines.*.price_list_position_id' => ['nullable', 'integer', 'min:1'],
            'lines.*.name' => ['required_with:lines', 'string', 'max:500'],
            'lines.*.unit_id' => ['nullable', 'integer', 'min:1'],
            'lines.*.unit_name' => ['required_with:lines', 'string', 'max:200'],
            'lines.*.unit_short_name' => ['required_with:lines', 'string', 'max:50'],
            'lines.*.quantity' => ['required_with:lines', 'numeric', 'min:0.0001'],
            'lines.*.recipient_unit_price' => ['required_with:lines', 'regex:/^\d+(\.\d{1,2})?$/'],
            'lines.*.customer_unit_price' => ['required_with:lines', 'regex:/^\d+(\.\d{1,2})?$/'],
            'lines.*.recipient_total' => ['required_with:lines', 'regex:/^\d+(\.\d{1,2})?$/'],
            'lines.*.customer_total' => ['required_with:lines', 'regex:/^\d+(\.\d{1,2})?$/'],
        ];
    }
}
