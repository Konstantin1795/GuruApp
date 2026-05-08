<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('company_roles', function (Blueprint $table) {
            $table->string('code')->primary();
            $table->string('description')->nullable();
        });

        Schema::create('project_roles', function (Blueprint $table) {
            $table->string('code')->primary();
            $table->string('description')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('project_roles');
        Schema::dropIfExists('company_roles');
    }
};

