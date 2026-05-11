<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('project_expense_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('project_id')->constrained('projects')->cascadeOnDelete();
            $table->string('name', 255);
            $table->boolean('markup_enabled')->default(false);
            $table->decimal('markup_percent', 5, 2)->nullable();
            $table->boolean('is_active')->default(true);
            $table->foreignId('created_by_user_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('updated_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['project_id', 'is_active', 'deleted_at']);
        });

        Schema::create('project_expense_item_profit_shares', function (Blueprint $table) {
            $table->id();
            $table->foreignId('expense_item_id')->constrained('project_expense_items')->cascadeOnDelete();
            $table->foreignId('counterparty_id')->constrained('counterparties')->restrictOnDelete();
            $table->decimal('percent', 5, 2);
            $table->timestamps();

            $table->unique(['expense_item_id', 'counterparty_id'], 'uq_pei_profit_item_counterparty');
        });

        Schema::create('project_expense_item_markup_shares', function (Blueprint $table) {
            $table->id();
            $table->foreignId('expense_item_id')->constrained('project_expense_items')->cascadeOnDelete();
            $table->foreignId('counterparty_id')->constrained('counterparties')->restrictOnDelete();
            $table->decimal('percent', 5, 2);
            $table->timestamps();

            $table->unique(['expense_item_id', 'counterparty_id'], 'uq_pei_markup_item_counterparty');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('project_expense_item_markup_shares');
        Schema::dropIfExists('project_expense_item_profit_shares');
        Schema::dropIfExists('project_expense_items');
    }
};
