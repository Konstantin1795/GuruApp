<?php

namespace App\Modules\Projects\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * @property int $id
 * @property int $project_id
 * @property string $name
 * @property bool $markup_enabled
 * @property string|null $markup_percent
 * @property bool $is_active
 * @property int $created_by_user_id
 * @property int|null $updated_by_user_id
 */
final class ProjectExpenseItem extends Model
{
    use SoftDeletes;

    protected $table = 'project_expense_items';

    protected $fillable = [
        'project_id',
        'name',
        'markup_enabled',
        'markup_percent',
        'is_active',
        'created_by_user_id',
        'updated_by_user_id',
    ];

    protected $casts = [
        'markup_enabled' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class, 'project_id');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function updatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by_user_id');
    }

    public function profitShares(): HasMany
    {
        return $this->hasMany(ProjectExpenseItemProfitShare::class, 'expense_item_id');
    }

    public function markupShares(): HasMany
    {
        return $this->hasMany(ProjectExpenseItemMarkupShare::class, 'expense_item_id');
    }
}
