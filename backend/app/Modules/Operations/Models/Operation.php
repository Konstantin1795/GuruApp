<?php

namespace App\Modules\Operations\Models;

use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Enums\OperationType;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int             $id
 * @property int             $project_id
 * @property int             $initiator_project_participant_id
 * @property OperationType   $operation_type
 * @property OperationStatus $operation_status
 */
final class Operation extends Model
{
    protected $table = 'operations';

    protected $fillable = [
        'project_id',
        'initiator_project_participant_id',
        'operation_type',
        'operation_status',
    ];

    protected $casts = [
        'operation_type'   => OperationType::class,
        'operation_status' => OperationStatus::class,
    ];

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class, 'project_id');
    }

    public function initiator(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'initiator_project_participant_id');
    }

    public function statusHistory(): HasMany
    {
        return $this->hasMany(OperationStatusHistory::class, 'operation_id')->orderBy('id');
    }
}
