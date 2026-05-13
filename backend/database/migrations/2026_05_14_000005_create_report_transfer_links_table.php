<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('report_transfer_links', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('report_operation_id')
                ->constrained('report_operations')
                ->cascadeOnDelete();

            $table->foreignId('transfer_operation_id')
                ->constrained('transfer_operations')
                ->cascadeOnDelete();

            $table->foreignId('created_by_user_id')->constrained('users')->restrictOnDelete();

            $table->timestamps();

            $table->unique(['report_operation_id', 'transfer_operation_id']);
            $table->unique(['transfer_operation_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_transfer_links');
    }
};
