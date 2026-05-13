<?php

namespace App\Modules\Operations\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property int $report_operation_id
 * @property int $transfer_operation_id
 * @property int $created_by_user_id
 */
final class ReportTransferLink extends Model
{
    protected $table = 'report_transfer_links';

    protected $fillable = [
        'report_operation_id',
        'transfer_operation_id',
        'created_by_user_id',
    ];

    public function reportOperation(): BelongsTo
    {
        return $this->belongsTo(ReportOperation::class, 'report_operation_id');
    }

    public function transferOperation(): BelongsTo
    {
        return $this->belongsTo(TransferOperation::class, 'transfer_operation_id');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }
}
