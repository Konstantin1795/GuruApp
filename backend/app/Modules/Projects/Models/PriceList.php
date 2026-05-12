<?php

namespace App\Modules\Projects\Models;

use App\Models\User;
use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * @property int $id
 * @property int $company_id
 * @property string $name
 * @property bool $is_active
 * @property int $created_by_user_id
 * @property int $created_by_counterparty_id
 * @property int|null $updated_by_user_id
 */
final class PriceList extends Model
{
    use SoftDeletes;

    protected $table = 'price_lists';

    protected $fillable = [
        'company_id',
        'name',
        'is_active',
        'created_by_user_id',
        'created_by_counterparty_id',
        'updated_by_user_id',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class, 'company_id');
    }

    public function createdByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function createdByCounterparty(): BelongsTo
    {
        return $this->belongsTo(Counterparty::class, 'created_by_counterparty_id');
    }

    public function updatedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by_user_id');
    }

    public function groups(): HasMany
    {
        return $this->hasMany(PriceListGroup::class, 'price_list_id');
    }

    public function positions(): HasMany
    {
        return $this->hasMany(PriceListPosition::class, 'price_list_id');
    }

    public function projectAttachments(): HasMany
    {
        return $this->hasMany(ProjectPriceList::class, 'price_list_id');
    }

    public function scopeVisible($query)
    {
        return $query->where('is_active', true)->whereNull('deleted_at');
    }
}
