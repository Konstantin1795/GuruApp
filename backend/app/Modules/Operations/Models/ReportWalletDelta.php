<?php

namespace App\Modules\Operations\Models;

use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Projects\Models\ProjectParticipantWallet;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int                $id
 * @property int                $report_operation_id
 * @property int                $project_participant_id
 * @property int|null           $wallet_id
 * @property string             $field_name
 * @property int                $delta_cents
 * @property \Carbon\Carbon     $applied_at
 * @property \Carbon\Carbon|null $reverted_at
 */
final class ReportWalletDelta extends Model
{
    protected $table = 'report_wallet_deltas';

    protected $fillable = [
        'report_operation_id',
        'project_participant_id',
        'wallet_id',
        'field_name',
        'delta_cents',
        'applied_at',
        'reverted_at',
    ];

    protected $casts = [
        'applied_at'  => 'datetime',
        'reverted_at' => 'datetime',
    ];

    public function reportOperation(): BelongsTo
    {
        return $this->belongsTo(ReportOperation::class, 'report_operation_id');
    }

    public function projectParticipant(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'project_participant_id');
    }

    public function wallet(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipantWallet::class, 'wallet_id');
    }
}
