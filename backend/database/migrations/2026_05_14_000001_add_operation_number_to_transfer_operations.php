<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transfer_operations', function (Blueprint $table): void {
            $table->string('operation_number', 32)->nullable()->after('id');
            $table->index(['project_id', 'operation_number']);
        });

        if (Schema::getConnection()->getDriverName() === 'sqlite') {
            $rows = DB::table('transfer_operations')->select('id')->orderBy('id')->get();
            foreach ($rows as $row) {
                DB::table('transfer_operations')
                    ->where('id', $row->id)
                    ->update(['operation_number' => 'TRF-'.$row->id]);
            }
        } else {
            DB::statement(
                "UPDATE transfer_operations SET operation_number = CONCAT('TRF-', id) WHERE operation_number IS NULL OR operation_number = ''",
            );
        }
    }

    public function down(): void
    {
        Schema::table('transfer_operations', function (Blueprint $table): void {
            $table->dropIndex(['project_id', 'operation_number']);
            $table->dropColumn('operation_number');
        });
    }
};
