<?php

namespace App\Modules\Projects\Models;

use App\Models\User;
use App\Modules\Companies\Models\Counterparty;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property int $project_id
 * @property int $price_list_id
 * @property int $attached_by_user_id
 * @property int|null $attached_by_counterparty_id
 */
final class ProjectPriceList extends Model
{
    protected $table = 'project_price_lists';

    protected $fillable = [
        'project_id',
        'price_list_id',
        'attached_by_user_id',
        'attached_by_counterparty_id',
    ];

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class, 'project_id');
    }

    public function priceList(): BelongsTo
    {
        return $this->belongsTo(PriceList::class, 'price_list_id');
    }

    public function attachedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'attached_by_user_id');
    }

    public function attachedByCounterparty(): BelongsTo
    {
        return $this->belongsTo(Counterparty::class, 'attached_by_counterparty_id');
    }
}
