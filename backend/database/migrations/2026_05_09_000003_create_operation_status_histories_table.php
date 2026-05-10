<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('operation_status_histories', function (Blueprint $table) {
            $table->id();

            $table->foreignId('operation_id')
                ->constrained('operations')
                ->cascadeOnDelete();

            $table->string('from_status')->nullable();
            $table->string('to_status');

            $table->foreignId('changed_by_project_participant_id')
                ->nullable()
                ->constrained('project_participants')
                ->nullOnDelete();

            $table->timestamp('created_at')->useCurrent();

            $table->index('operation_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('operation_status_histories');
    }
};
