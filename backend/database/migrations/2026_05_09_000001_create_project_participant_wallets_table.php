<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('project_participant_wallets', function (Blueprint $table) {
            $table->id();

            $table->foreignId('project_participant_id')
                ->unique()
                ->constrained('project_participants')
                ->cascadeOnDelete();

            // Personal pocket: what this participant personally earns/receives
            $table->decimal('personal_balance', 15, 2)->default('0.00');
            $table->decimal('personal_earned', 15, 2)->default('0.00');
            $table->decimal('personal_received', 15, 2)->default('0.00');

            // Accountable pocket: funds the participant manages on behalf of the project
            $table->decimal('accountable_balance', 15, 2)->default('0.00');
            $table->decimal('accountable_received', 15, 2)->default('0.00');
            $table->decimal('accountable_spent', 15, 2)->default('0.00');

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('project_participant_wallets');
    }
};
