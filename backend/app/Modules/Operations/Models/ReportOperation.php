<?php

namespace App\Modules\Operations\Models;

use App\Modules\Companies\Models\Company;
use App\Modules\Companies\Models\Counterparty;
use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Projects\Models\Project;
use App\Modules\Projects\Models\ProjectExpenseItem;
use App\Modules\Projects\Models\ProjectParticipant;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int                $id
 * @property string|null        $operation_number
 * @property int                $company_id
 * @property int                $project_id
 * @property int                $initiator_project_participant_id
 * @property int                $recipient_counterparty_id
 * @property int                $recipient_project_participant_id
 * @property int                $customer_project_participant_id
 * @property int                $expense_item_id
 * @property string             $operation_date
 * @property OperationStatus    $operation_status
 * @property string             $recipient_amount
 * @property string             $customer_base_amount
 * @property string             $markup_amount
 * @property string             $customer_total_amount
 * @property string             $profit_amount
 * @property string|null        $comment
 * @property \Carbon\Carbon|null $wallets_applied_at
 * @property \Carbon\Carbon|null $wallets_reverted_at
 * @property \Carbon\Carbon|null $waiting_period_started_at
 * @property \Carbon\Carbon|null $completed_at
 * @property int                $created_by_user_id
 * @property int|null           $updated_by_user_id
 */
final class ReportOperation extends Model
{
    protected $table = 'report_operations';

    protected $fillable = [
        'operation_number',
        'company_id',
        'project_id',
        'initiator_project_participant_id',
        'recipient_counterparty_id',
        'recipient_project_participant_id',
        'customer_project_participant_id',
        'expense_item_id',
        'operation_date',
        'operation_status',
        'recipient_amount',
        'customer_base_amount',
        'markup_amount',
        'customer_total_amount',
        'profit_amount',
        'comment',
        'wallets_applied_at',
        'wallets_reverted_at',
        'waiting_period_started_at',
        'completed_at',
        'created_by_user_id',
        'updated_by_user_id',
    ];

    protected $casts = [
        'operation_date'            => 'date',
        'operation_status'          => OperationStatus::class,
        'recipient_amount'          => 'decimal:2',
        'customer_base_amount'      => 'decimal:2',
        'markup_amount'             => 'decimal:2',
        'customer_total_amount'     => 'decimal:2',
        'profit_amount'             => 'decimal:2',
        'wallets_applied_at'        => 'datetime',
        'wallets_reverted_at'       => 'datetime',
        'waiting_period_started_at' => 'datetime',
        'completed_at'              => 'datetime',
    ];

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class, 'company_id');
    }

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class, 'project_id');
    }

    public function initiator(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'initiator_project_participant_id');
    }

    public function recipientCounterparty(): BelongsTo
    {
        return $this->belongsTo(Counterparty::class, 'recipient_counterparty_id');
    }

    public function recipientParticipant(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'recipient_project_participant_id');
    }

    public function customerParticipant(): BelongsTo
    {
        return $this->belongsTo(ProjectParticipant::class, 'customer_project_participant_id');
    }

    public function expenseItem(): BelongsTo
    {
        return $this->belongsTo(ProjectExpenseItem::class, 'expense_item_id');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function lines(): HasMany
    {
        return $this->hasMany(ReportOperationLine::class, 'report_operation_id')->orderBy('sort_order');
    }

    /** @return HasMany<ReportWalletDelta, ReportOperation> */
    public function walletDeltas(): HasMany
    {
        return $this->hasMany(ReportWalletDelta::class, 'report_operation_id');
    }

    /** @return HasMany<ReportTransferLink, ReportOperation> */
    public function transferLinks(): HasMany
    {
        return $this->hasMany(ReportTransferLink::class, 'report_operation_id');
    }

    /** @return HasMany<ReportOperationStatusHistory, ReportOperation> */
    public function statusHistories(): HasMany
    {
        return $this->hasMany(ReportOperationStatusHistory::class, 'report_operation_id')->orderBy('id');
    }
}
