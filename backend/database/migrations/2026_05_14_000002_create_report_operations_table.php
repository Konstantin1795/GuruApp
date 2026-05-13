<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('report_operations', function (Blueprint $table): void {
            $table->id();
            $table->string('operation_number', 32)->nullable();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('project_id')->constrained('projects')->cascadeOnDelete();

            $table->foreignId('initiator_project_participant_id')
                ->constrained('project_participants')
                ->restrictOnDelete();

            $table->foreignId('recipient_counterparty_id')
                ->constrained('counterparties')
                ->restrictOnDelete();

            $table->foreignId('recipient_project_participant_id')
                ->constrained('project_participants')
                ->restrictOnDelete();

            $table->foreignId('customer_project_participant_id')
                ->constrained('project_participants')
                ->restrictOnDelete();

            $table->foreignId('expense_item_id')
                ->constrained('project_expense_items')
                ->restrictOnDelete();

            $table->date('operation_date');

            $table->string('operation_status')->index();

            $table->decimal('recipient_amount', 15, 2)->default('0.00');
            $table->decimal('customer_base_amount', 15, 2)->default('0.00');
            $table->decimal('markup_amount', 15, 2)->default('0.00');
            $table->decimal('customer_total_amount', 15, 2)->default('0.00');
            $table->decimal('profit_amount', 15, 2)->default('0.00');

            $table->text('comment')->nullable();

            $table->timestamp('wallets_applied_at')->nullable();
            $table->timestamp('wallets_reverted_at')->nullable();
            $table->timestamp('waiting_period_started_at')->nullable();
            $table->timestamp('completed_at')->nullable();

            $table->foreignId('created_by_user_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('updated_by_user_id')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();

            $table->unique(['company_id', 'operation_number']);
            $table->index(['project_id', 'operation_status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_operations');
    }
};
