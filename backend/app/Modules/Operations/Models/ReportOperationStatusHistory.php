<?php

namespace App\Modules\Operations\Models;

use App\Modules\Operations\Enums\OperationStatus;
use App\Models\User;
use App\Modules\Projects\Models\ProjectParticipant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int|null $from_status
 * @property string   $to_status
 */
final class ReportOperationStatusHistory extends Model
{
    public $timestamps = false;

    protected $table = 'report_operation_status_histories';

    protected $fillable = [
        'report_operation_id',
        'from_status',
        'to_status',
        'changed_by_project_participant_id',
        'comment',
        'author_user_id',
        'author_full_name',
        'created_at',
    ];

    protected $casts = [
        'to_status'   => OperationStatus::class,
        'created_at'  => 'datetime',
    ];

    public function reportOperation(): BelongsTo
    {
        return $this->belongsTo(ReportOperation::class, 'report_operation_id');
    }

    public function changedBy(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'changed_by_project_participant_id');
    }

    public function authorUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'author_user_id');
    }
}
