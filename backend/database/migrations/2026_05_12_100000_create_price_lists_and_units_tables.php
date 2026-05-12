<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('units', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->nullable()->constrained('companies')->cascadeOnDelete();
            $table->string('name', 255);
            $table->string('short_name', 32);
            $table->boolean('is_system')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['company_id', 'is_active']);
            $table->index(['is_system', 'is_active']);
        });

        Schema::create('price_lists', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->string('name', 255);
            $table->boolean('is_active')->default(true);
            $table->foreignId('created_by_user_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('created_by_counterparty_id')->constrained('counterparties')->restrictOnDelete();
            $table->foreignId('updated_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['company_id', 'is_active', 'deleted_at']);
            $table->index(['company_id', 'created_by_counterparty_id', 'is_active', 'deleted_at'], 'idx_price_lists_owner_cp');
        });

        Schema::create('price_list_groups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('price_list_id')->constrained('price_lists')->cascadeOnDelete();
            $table->string('name', 255);
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->foreignId('created_by_user_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('updated_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['price_list_id', 'sort_order']);
            $table->index(['price_list_id', 'is_active', 'deleted_at']);
        });

        Schema::create('price_list_positions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('price_list_id')->constrained('price_lists')->cascadeOnDelete();
            $table->foreignId('price_list_group_id')->constrained('price_list_groups')->cascadeOnDelete();
            $table->string('service_name', 512);
            $table->foreignId('unit_id')->constrained('units')->restrictOnDelete();
            $table->decimal('recipient_unit_price', 15, 2);
            $table->decimal('customer_unit_price', 15, 2);
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->foreignId('created_by_user_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('updated_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['price_list_group_id', 'sort_order']);
            $table->index(['price_list_id', 'is_active', 'deleted_at']);
        });

        Schema::create('project_price_lists', function (Blueprint $table) {
            $table->id();
            $table->foreignId('project_id')->constrained('projects')->cascadeOnDelete();
            $table->foreignId('price_list_id')->constrained('price_lists')->cascadeOnDelete();
            $table->foreignId('attached_by_user_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('attached_by_counterparty_id')->nullable()->constrained('counterparties')->nullOnDelete();
            $table->timestamps();

            $table->unique(['project_id', 'price_list_id'], 'uq_project_price_list');
            $table->index(['price_list_id']);
        });

        $now = now();
        $systemUnits = [
            ['name' => 'Штука', 'short_name' => 'шт'],
            ['name' => 'Квадратный метр', 'short_name' => 'м²'],
            ['name' => 'Погонный метр', 'short_name' => 'п.м.'],
            ['name' => 'Час', 'short_name' => 'ч'],
            ['name' => 'Килограмм', 'short_name' => 'кг'],
            ['name' => 'Тонна', 'short_name' => 'т'],
            ['name' => 'Кубический метр', 'short_name' => 'м³'],
            ['name' => 'Услуга', 'short_name' => 'усл.'],
        ];

        foreach ($systemUnits as $row) {
            DB::table('units')->insert([
                'company_id' => null,
                'name' => $row['name'],
                'short_name' => $row['short_name'],
                'is_system' => true,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('project_price_lists');
        Schema::dropIfExists('price_list_positions');
        Schema::dropIfExists('price_list_groups');
        Schema::dropIfExists('price_lists');
        Schema::dropIfExists('units');
    }
};
