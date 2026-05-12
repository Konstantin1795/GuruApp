<?php

namespace App\Modules\Projects\Models;

use App\Modules\Companies\Models\Company;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int $id
 * @property int $company_id
 * @property string $name
 * @property int $progress_percent
 * @property bool $is_active
 */
final class Project extends Model
{
    protected $table = 'projects';

    protected $fillable = [
        'company_id',
        'name',
        'progress_percent',
        'is_active',
    ];

    protected $casts = [
        'progress_percent' => 'integer',
        'is_active' => 'boolean',
    ];

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class, 'company_id');
    }

    public function participants(): HasMany
    {
        return $this->hasMany(ProjectParticipant::class, 'project_id');
    }

    public function expenseItems(): HasMany
    {
        return $this->hasMany(ProjectExpenseItem::class, 'project_id');
    }

    public function projectPriceLists(): HasMany
    {
        return $this->hasMany(ProjectPriceList::class, 'project_id');
    }
}

