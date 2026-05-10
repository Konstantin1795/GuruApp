<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('counterparties', function (Blueprint $table) {
            $table->string('full_name')->nullable()->after('user_id');
            $table->string('email')->nullable()->after('full_name');

            $table->index(['company_id', 'email']);
        });
    }

    public function down(): void
    {
        Schema::table('counterparties', function (Blueprint $table) {
            $table->dropIndex(['company_id', 'email']);
            $table->dropColumn(['email', 'full_name']);
        });
    }
};

