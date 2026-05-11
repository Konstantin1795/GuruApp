<?php

namespace App\Modules\Projects\Models;

use App\Modules\Companies\Models\Counterparty;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property int $expense_item_id
 * @property int $counterparty_id
 * @property string $percent
 */
final class ProjectExpenseItemMarkupShare extends Model
{
    protected $table = 'project_expense_item_markup_shares';

    protected $fillable = [
        'expense_item_id',
        'counterparty_id',
        'percent',
    ];

    public function expenseItem(): BelongsTo
    {
        return $this->belongsTo(ProjectExpenseItem::class, 'expense_item_id');
    }

    public function counterparty(): BelongsTo
    {
        return $this->belongsTo(Counterparty::class, 'counterparty_id');
    }
}
