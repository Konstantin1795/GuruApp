<?php

namespace App\Modules\Companies\Models;

use App\Models\User;
use App\Modules\Dictionaries\Models\CompanyRole;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Counterparty can exist without user_id (invite-first).
 *
 * @property int $id
 * @property int $company_id
 * @property int|null $user_id
 * @property string $company_role_code
 * @property bool $is_active
 */
final class Counterparty extends Model
{
    protected $table = 'counterparties';

    protected $fillable = [
        'company_id',
        'user_id',
        'full_name',
        'email',
        'company_role_code',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class, 'company_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function role(): BelongsTo
    {
        return $this->belongsTo(CompanyRole::class, 'company_role_code', 'code');
    }

    public function projectParticipants(): HasMany
    {
        return $this->hasMany(ProjectParticipant::class, 'counterparty_id');
    }
}

