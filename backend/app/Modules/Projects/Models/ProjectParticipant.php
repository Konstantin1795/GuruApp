<?php

namespace App\Modules\Projects\Models;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Dictionaries\Models\ProjectRole;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * @property int $id
 * @property int $project_id
 * @property int $counterparty_id
 * @property string $project_role_code
 * @property string $level
 * @property bool $is_active
 */
final class ProjectParticipant extends Model
{
    protected $table = 'project_participants';

    protected $fillable = [
        'project_id',
        'counterparty_id',
        'project_role_code',
        'level',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class, 'project_id');
    }

    public function counterparty(): BelongsTo
    {
        return $this->belongsTo(Counterparty::class, 'counterparty_id');
    }

    public function role(): BelongsTo
    {
        return $this->belongsTo(ProjectRole::class, 'project_role_code', 'code');
    }

    public function wallet(): HasOne
    {
        return $this->hasOne(ProjectParticipantWallet::class, 'project_participant_id');
    }
}

