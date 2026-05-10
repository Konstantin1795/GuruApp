<?php

namespace App\Modules\Projects\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int    $id
 * @property int    $project_participant_id
 * @property string $personal_balance
 * @property string $personal_earned
 * @property string $personal_received
 * @property string $accountable_balance
 * @property string $accountable_received
 * @property string $accountable_spent
 */
final class ProjectParticipantWallet extends Model
{
    protected $table = 'project_participant_wallets';

    protected $fillable = [
        'project_participant_id',
        'personal_balance',
        'personal_earned',
        'personal_received',
        'accountable_balance',
        'accountable_received',
        'accountable_spent',
    ];

    /** Store decimals as strings to prevent float precision loss. */
    protected $casts = [
        'personal_balance'     => 'decimal:2',
        'personal_earned'      => 'decimal:2',
        'personal_received'    => 'decimal:2',
        'accountable_balance'  => 'decimal:2',
        'accountable_received' => 'decimal:2',
        'accountable_spent'    => 'decimal:2',
    ];

    public function participant(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'project_participant_id');
    }
}
