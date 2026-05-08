<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('companies', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->foreignId('created_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('counterparties', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('company_role_code');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('company_role_code')->references('code')->on('company_roles')->restrictOnDelete();
            $table->unique(['company_id', 'user_id'], 'uq_counterparties_company_user');
        });

        Schema::create('projects', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->string('name');
            $table->unsignedTinyInteger('progress_percent')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['company_id', 'is_active']);
        });

        Schema::create('project_participants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('project_id')->constrained('projects')->cascadeOnDelete();
            $table->foreignId('counterparty_id')->constrained('counterparties')->cascadeOnDelete();
            $table->string('project_role_code');
            $table->enum('level', ['first', 'second']);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('project_role_code')->references('code')->on('project_roles')->restrictOnDelete();
            $table->unique(['project_id', 'counterparty_id'], 'uq_project_participants_project_counterparty');
            $table->index(['project_id', 'project_role_code']);
        });

        // Postgres CHECK constraint for progress_percent 0..100
        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE projects ADD CONSTRAINT chk_projects_progress_percent CHECK (progress_percent >= 0 AND progress_percent <= 100)');
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('project_participants');
        Schema::dropIfExists('projects');
        Schema::dropIfExists('counterparties');
        Schema::dropIfExists('companies');
    }
};

