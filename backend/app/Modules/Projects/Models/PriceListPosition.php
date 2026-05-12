<?php

namespace App\Modules\Projects\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * @property int $id
 * @property int $price_list_id
 * @property int $price_list_group_id
 * @property string $service_name
 * @property int $unit_id
 * @property string $recipient_unit_price
 * @property string $customer_unit_price
 * @property int $sort_order
 * @property bool $is_active
 */
final class PriceListPosition extends Model
{
    use SoftDeletes;

    protected $table = 'price_list_positions';

    protected $fillable = [
        'price_list_id',
        'price_list_group_id',
        'service_name',
        'unit_id',
        'recipient_unit_price',
        'customer_unit_price',
        'sort_order',
        'is_active',
        'created_by_user_id',
        'updated_by_user_id',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'sort_order' => 'integer',
        'recipient_unit_price' => 'string',
        'customer_unit_price' => 'string',
    ];

    public function priceList(): BelongsTo
    {
        return $this->belongsTo(PriceList::class, 'price_list_id');
    }

    public function group(): BelongsTo
    {
        return $this->belongsTo(PriceListGroup::class, 'price_list_group_id');
    }

    public function unit(): BelongsTo
    {
        return $this->belongsTo(Unit::class, 'unit_id');
    }

    public function createdByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function updatedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by_user_id');
    }

    public function scopeVisible($query)
    {
        return $query->where('is_active', true)->whereNull('deleted_at');
    }
}
