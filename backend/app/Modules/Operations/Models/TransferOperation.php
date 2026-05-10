<?php

namespace App\Modules\Operations\Models;

use App\Modules\Companies\Models\Counterparty;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Enums\TransferTargetType;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int                $id
 * @property int                $operation_id
 * @property int                $project_id
 * @property int                $initiator_project_participant_id
 * @property int                $sender_project_participant_id
 * @property int                $receiver_project_participant_id
 * @property int|null           $receiver_counterparty_id
 * @property TransferTargetType $transfer_target_type
 * @property string             $amount
 * @property string|null        $comment
 * @property OperationStatus    $operation_status
 * @property \Carbon\Carbon|null $wallets_applied_at
 * @property \Carbon\Carbon|null $wallets_reverted_at
 * @property \Carbon\Carbon|null $waiting_period_started_at
 */
final class TransferOperation extends Model
{
    protected $table = 'transfer_operations';

    protected $fillable = [
        'operation_id',
        'project_id',
        'initiator_project_participant_id',
        'sender_project_participant_id',
        'receiver_project_participant_id',
        'receiver_counterparty_id',
        'transfer_target_type',
        'amount',
        'comment',
        'operation_status',
        'wallets_applied_at',
        'wallets_reverted_at',
        'waiting_period_started_at',
    ];

    protected $casts = [
        'transfer_target_type'      => TransferTargetType::class,
        'amount'                    => 'decimal:2',
        'operation_status'          => OperationStatus::class,
        'wallets_applied_at'        => 'datetime',
        'wallets_reverted_at'       => 'datetime',
        'waiting_period_started_at' => 'datetime',
    ];

    public function operation(): BelongsTo
    {
        return $this->belongsTo(Operation::class, 'operation_id');
    }

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class, 'project_id');
    }

    public function initiator(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'initiator_project_participant_id');
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'sender_project_participant_id');
    }

    public function receiver(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'receiver_project_participant_id');
    }

    public function receiverCounterparty(): BelongsTo
    {
        return $this->belongsTo(Counterparty::class, 'receiver_counterparty_id');
    }
}
