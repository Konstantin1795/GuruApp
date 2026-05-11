<?php

use App\Modules\Operations\Enums\OperationStatus;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('income_operations', function (Blueprint $table) {
            $table->id();

            $table->foreignId('operation_id')
                ->unique()
                ->constrained('operations')
                ->cascadeOnDelete();

            $table->foreignId('project_id')
                ->constrained('projects')
                ->cascadeOnDelete();

            $table->foreignId('initiator_project_participant_id')
                ->constrained('project_participants')
                ->restrictOnDelete();

            $table->foreignId('project_head_project_participant_id')
                ->constrained('project_participants')
                ->restrictOnDelete();

            $table->foreignId('customer_project_participant_id')
                ->constrained('project_participants')
                ->restrictOnDelete();

            $table->decimal('amount', 15, 2);
            $table->string('comment')->nullable();

            $table->string('operation_status')->default(OperationStatus::CREATED->value);

            $table->timestamp('wallets_applied_at')->nullable();
            $table->timestamp('wallets_reverted_at')->nullable();
            $table->timestamp('waiting_period_started_at')->nullable();

            $table->timestamps();

            $table->index(['project_id', 'operation_status']);
            $table->index(['customer_project_participant_id']);
            $table->index(['created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('income_operations');
    }
};
