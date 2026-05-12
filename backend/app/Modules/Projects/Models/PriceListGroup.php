<?php

namespace App\Modules\Projects\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * @property int $id
 * @property int $price_list_id
 * @property string $name
 * @property int $sort_order
 * @property bool $is_active
 */
final class PriceListGroup extends Model
{
    use SoftDeletes;

    protected $table = 'price_list_groups';

    protected $fillable = [
        'price_list_id',
        'name',
        'sort_order',
        'is_active',
        'created_by_user_id',
        'updated_by_user_id',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];

    public function priceList(): BelongsTo
    {
        return $this->belongsTo(PriceList::class, 'price_list_id');
    }

    public function createdByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function updatedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by_user_id');
    }

    public function positions(): HasMany
    {
        return $this->hasMany(PriceListPosition::class, 'price_list_group_id');
    }

    public function scopeVisible($query)
    {
        return $query->where('is_active', true)->whereNull('deleted_at');
    }
}
