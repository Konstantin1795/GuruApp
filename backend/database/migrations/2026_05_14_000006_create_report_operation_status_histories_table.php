<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('report_operation_status_histories', function (Blueprint $table): void {
            $table->id();

            $table->foreignId('report_operation_id')
                ->constrained('report_operations')
                ->cascadeOnDelete();

            $table->string('from_status')->nullable();
            $table->string('to_status');

            $table->foreignId('changed_by_project_participant_id')
                ->nullable()
                ->constrained('project_participants')
                ->nullOnDelete();

            $table->text('comment')->nullable();
            $table->foreignId('author_user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();
            $table->string('author_full_name')->nullable();

            $table->timestamp('created_at')->useCurrent();

            $table->index('report_operation_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_operation_status_histories');
    }
};
