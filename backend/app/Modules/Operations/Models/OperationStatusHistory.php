<?php

namespace App\Modules\Operations\Models;

use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int                  $id
 * @property int                  $operation_id
 * @property OperationStatus|null $from_status
 * @property OperationStatus      $to_status
 * @property int|null             $changed_by_project_participant_id
 * @property string|null          $comment
 * @property int|null             $author_user_id
 * @property string|null          $author_full_name
 */
final class OperationStatusHistory extends Model
{
    protected $table = 'operation_status_histories';

    public $timestamps = false;

    protected $fillable = [
        'operation_id',
        'from_status',
        'to_status',
        'changed_by_project_participant_id',
        'comment',
        'author_user_id',
        'author_full_name',
    ];

    protected $casts = [
        'from_status' => OperationStatus::class,
        'to_status'   => OperationStatus::class,
        'created_at'  => 'datetime',
    ];

    public function operation(): BelongsTo
    {
        return $this->belongsTo(Operation::class, 'operation_id');
    }

    public function changedBy(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'changed_by_project_participant_id');
    }
}
