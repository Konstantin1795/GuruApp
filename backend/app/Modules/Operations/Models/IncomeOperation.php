<?php

namespace App\Modules\Operations\Models;

use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Modules\Operations\Enums\OperationStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int                $id
 * @property int                $operation_id
 * @property int                $project_id
 * @property int                $initiator_project_participant_id
 * @property int                $project_head_project_participant_id
 * @property int                $customer_project_participant_id
 * @property string             $amount
 * @property string|null      $comment
 * @property OperationStatus    $operation_status
 * @property \Carbon\Carbon|null $wallets_applied_at
 * @property \Carbon\Carbon|null $wallets_reverted_at
 * @property \Carbon\Carbon|null $waiting_period_started_at
 */
final class IncomeOperation extends Model
{
    protected $table = 'income_operations';

    protected $fillable = [
        'operation_id',
        'project_id',
        'initiator_project_participant_id',
        'project_head_project_participant_id',
        'customer_project_participant_id',
        'amount',
        'comment',
        'operation_status',
        'wallets_applied_at',
        'wallets_reverted_at',
        'waiting_period_started_at',
    ];

    protected $casts = [
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

    /** @return BelongsTo<Project, IncomeOperation> */
    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class, 'project_id');
    }

    public function initiator(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'initiator_project_participant_id');
    }

    public function projectHead(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'project_head_project_participant_id');
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'customer_project_participant_id');
    }
}
