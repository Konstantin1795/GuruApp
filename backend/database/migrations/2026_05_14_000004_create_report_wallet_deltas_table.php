<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('report_wallet_deltas', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('report_operation_id')
                ->constrained('report_operations')
                ->cascadeOnDelete();

            $table->foreignId('project_participant_id')
                ->constrained('project_participants')
                ->restrictOnDelete();

            $table->foreignId('wallet_id')
                ->nullable()
                ->constrained('project_participant_wallets')
                ->nullOnDelete();

            $table->string('field_name', 64);
            /** Signed cents applied to field_name (e.g. personal_earned, accountable_balance). */
            $table->bigInteger('delta_cents');

            $table->timestamp('applied_at')->useCurrent();
            $table->timestamp('reverted_at')->nullable();

            $table->timestamps();

            $table->index(['report_operation_id', 'reverted_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_wallet_deltas');
    }
};
