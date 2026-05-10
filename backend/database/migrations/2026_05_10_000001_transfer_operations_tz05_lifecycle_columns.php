<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transfer_operations', function (Blueprint $table) {
            $table->foreignId('receiver_counterparty_id')
                ->nullable()
                ->after('receiver_project_participant_id')
                ->constrained('counterparties')
                ->nullOnDelete();

            $table->timestamp('wallets_applied_at')->nullable()->after('operation_status');
            $table->timestamp('wallets_reverted_at')->nullable()->after('wallets_applied_at');
            $table->timestamp('waiting_period_started_at')->nullable()->after('wallets_reverted_at');
        });

        Schema::table('operation_status_histories', function (Blueprint $table) {
            $table->text('comment')->nullable()->after('changed_by_project_participant_id');
            $table->foreignId('author_user_id')
                ->nullable()
                ->after('comment')
                ->constrained('users')
                ->nullOnDelete();
            $table->string('author_full_name')->nullable()->after('author_user_id');
        });
    }

    public function down(): void
    {
        Schema::table('operation_status_histories', function (Blueprint $table) {
            $table->dropForeign(['author_user_id']);
            $table->dropColumn(['comment', 'author_user_id', 'author_full_name']);
        });

        Schema::table('transfer_operations', function (Blueprint $table) {
            $table->dropForeign(['receiver_counterparty_id']);
            $table->dropColumn([
                'receiver_counterparty_id',
                'wallets_applied_at',
                'wallets_reverted_at',
                'waiting_period_started_at',
            ]);
        });
    }
};
