<?php

use App\Modules\Operations\Enums\OperationStatus;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transfer_operations', function (Blueprint $table) {
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

            $table->foreignId('sender_project_participant_id')
                ->constrained('project_participants')
                ->restrictOnDelete();

            $table->foreignId('receiver_project_participant_id')
                ->constrained('project_participants')
                ->restrictOnDelete();

            $table->string('transfer_target_type');
            $table->decimal('amount', 15, 2);
            $table->string('comment')->nullable();
            $table->string('operation_status')->default(OperationStatus::CREATED->value);
            $table->timestamps();

            $table->index(['project_id', 'operation_status']);
            $table->index(['project_id', 'transfer_target_type']);
            $table->index(['sender_project_participant_id']);
            $table->index(['receiver_project_participant_id']);
            $table->index(['created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transfer_operations');
    }
};
