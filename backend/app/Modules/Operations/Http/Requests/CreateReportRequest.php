<?php

declare(strict_types=1);

namespace App\Modules\Operations\Http\Requests;

use App\Modules\Operations\Enums\ReportLineSourceType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class CreateReportRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'expense_item_id' => ['required', 'integer', 'min:1'],
            'recipient_counterparty_id' => ['required', 'integer', 'min:1'],
            'operation_date' => ['required', 'date_format:Y-m-d'],
            'comment' => ['nullable', 'string', 'max:5000'],
            'lines' => ['required', 'array', 'min:1'],
            'lines.*.source_type' => ['required', 'string', Rule::enum(ReportLineSourceType::class)],
            'lines.*.price_list_id' => ['nullable', 'integer', 'min:1'],
            'lines.*.price_list_group_id' => ['nullable', 'integer', 'min:1'],
            'lines.*.price_list_position_id' => ['nullable', 'integer', 'min:1'],
            'lines.*.name' => ['required', 'string', 'max:500'],
            'lines.*.unit_id' => ['nullable', 'integer', 'min:1'],
            'lines.*.unit_name' => ['required', 'string', 'max:200'],
            'lines.*.unit_short_name' => ['required', 'string', 'max:50'],
            'lines.*.quantity' => ['required', 'numeric', 'min:0.0001'],
            'lines.*.recipient_unit_price' => ['required', 'regex:/^\d+(\.\d{1,2})?$/'],
            'lines.*.customer_unit_price' => ['required', 'regex:/^\d+(\.\d{1,2})?$/'],
            'lines.*.recipient_total' => ['required', 'regex:/^\d+(\.\d{1,2})?$/'],
            'lines.*.customer_total' => ['required', 'regex:/^\d+(\.\d{1,2})?$/'],
        ];
    }
}
