<?php

namespace App\Modules\Projects\Models;

use App\Modules\Companies\Models\Company;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property int|null $company_id
 * @property string $name
 * @property string $short_name
 * @property bool $is_system
 * @property bool $is_active
 */
final class Unit extends Model
{
    protected $table = 'units';

    protected $fillable = [
        'company_id',
        'name',
        'short_name',
        'is_system',
        'is_active',
    ];

    protected $casts = [
        'is_system' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class, 'company_id');
    }
}
