<?php

use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Operations\Enums\OperationType;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('operations', function (Blueprint $table) {
            $table->id();

            $table->foreignId('project_id')
                ->constrained('projects')
                ->cascadeOnDelete();

            $table->foreignId('initiator_project_participant_id')
                ->constrained('project_participants')
                ->restrictOnDelete();

            $table->string('operation_type');
            $table->string('operation_status')->default(OperationStatus::CREATED->value);

            $table->timestamps();

            $table->index(['project_id', 'operation_status']);
            $table->index('initiator_project_participant_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('operations');
    }
};
