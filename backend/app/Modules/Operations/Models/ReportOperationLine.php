<?php

namespace App\Modules\Operations\Models;

use App\Modules\Operations\Enums\ReportLineSourceType;
use App\Modules\Projects\Models\PriceList;
use App\Modules\Projects\Models\Unit;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int                 $id
 * @property int                 $report_operation_id
 * @property ReportLineSourceType $source_type
 * @property int|null            $price_list_id
 * @property int|null            $price_list_group_id
 * @property int|null            $price_list_position_id
 * @property string              $name
 * @property int|null            $unit_id
 * @property string              $unit_name
 * @property string              $unit_short_name
 * @property string              $quantity
 * @property string              $recipient_unit_price
 * @property string              $customer_unit_price
 * @property string              $recipient_total
 * @property string              $customer_total
 * @property int                 $sort_order
 */
final class ReportOperationLine extends Model
{
    protected $table = 'report_operation_lines';

    protected $fillable = [
        'report_operation_id',
        'source_type',
        'price_list_id',
        'price_list_group_id',
        'price_list_position_id',
        'name',
        'unit_id',
        'unit_name',
        'unit_short_name',
        'quantity',
        'recipient_unit_price',
        'customer_unit_price',
        'recipient_total',
        'customer_total',
        'sort_order',
    ];

    protected $casts = [
        'source_type'           => ReportLineSourceType::class,
        'quantity'              => 'decimal:4',
        'recipient_unit_price'  => 'decimal:2',
        'customer_unit_price'   => 'decimal:2',
        'recipient_total'       => 'decimal:2',
        'customer_total'        => 'decimal:2',
    ];

    public function reportOperation(): BelongsTo
    {
        return $this->belongsTo(ReportOperation::class, 'report_operation_id');
    }

    public function priceList(): BelongsTo
    {
        return $this->belongsTo(PriceList::class, 'price_list_id');
    }

    public function unit(): BelongsTo
    {
        return $this->belongsTo(Unit::class, 'unit_id');
    }
}
