<?php

namespace App\Modules\Companies\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int $id
 * @property string $name
 * @property int|null $created_by_user_id
 * @property int $is_active
 */
final class Company extends Model
{
    protected $table = 'companies';

    protected $fillable = [
        'name',
        'created_by_user_id',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function counterparties(): HasMany
    {
        return $this->hasMany(Counterparty::class, 'company_id');
    }
}

