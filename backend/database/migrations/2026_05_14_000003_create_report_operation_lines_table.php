<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('report_operation_lines', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('report_operation_id')
                ->constrained('report_operations')
                ->cascadeOnDelete();

            $table->string('source_type', 32);

            $table->foreignId('price_list_id')->nullable()->constrained('price_lists')->nullOnDelete();
            $table->unsignedBigInteger('price_list_group_id')->nullable();
            $table->unsignedBigInteger('price_list_position_id')->nullable();

            $table->string('name');

            $table->foreignId('unit_id')->nullable()->constrained('units')->nullOnDelete();
            $table->string('unit_name');
            $table->string('unit_short_name');

            $table->decimal('quantity', 15, 4);

            $table->decimal('recipient_unit_price', 15, 2);
            $table->decimal('customer_unit_price', 15, 2);

            $table->decimal('recipient_total', 15, 2);
            $table->decimal('customer_total', 15, 2);

            $table->unsignedInteger('sort_order')->default(0);

            $table->timestamps();

            $table->index(['report_operation_id', 'sort_order']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_operation_lines');
    }
};
