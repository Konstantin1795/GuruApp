<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        $indexes = [
            'idx_companies_is_active' => 'CREATE INDEX IF NOT EXISTS idx_companies_is_active ON companies (is_active)',
            'idx_companies_created_at' => 'CREATE INDEX IF NOT EXISTS idx_companies_created_at ON companies (created_at)',

            'idx_counterparties_company_id' => 'CREATE INDEX IF NOT EXISTS idx_counterparties_company_id ON counterparties (company_id)',
            'idx_counterparties_user_id' => 'CREATE INDEX IF NOT EXISTS idx_counterparties_user_id ON counterparties (user_id)',
            'idx_counterparties_company_role_code' => 'CREATE INDEX IF NOT EXISTS idx_counterparties_company_role_code ON counterparties (company_role_code)',
            'idx_counterparties_company_email' => 'CREATE INDEX IF NOT EXISTS idx_counterparties_company_email ON counterparties (company_id, email)',
            'idx_counterparties_company_role' => 'CREATE INDEX IF NOT EXISTS idx_counterparties_company_role ON counterparties (company_id, company_role_code)',

            'idx_projects_company_id' => 'CREATE INDEX IF NOT EXISTS idx_projects_company_id ON projects (company_id)',
            'idx_projects_is_active' => 'CREATE INDEX IF NOT EXISTS idx_projects_is_active ON projects (is_active)',
            'idx_projects_created_at' => 'CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects (created_at)',

            'idx_project_participants_project_id' => 'CREATE INDEX IF NOT EXISTS idx_project_participants_project_id ON project_participants (project_id)',
            'idx_project_participants_counterparty_id' => 'CREATE INDEX IF NOT EXISTS idx_project_participants_counterparty_id ON project_participants (counterparty_id)',
            'idx_project_participants_role_code' => 'CREATE INDEX IF NOT EXISTS idx_project_participants_role_code ON project_participants (project_role_code)',

            'idx_project_participant_wallets_created_at' => 'CREATE INDEX IF NOT EXISTS idx_project_participant_wallets_created_at ON project_participant_wallets (created_at)',

            'idx_operations_project_id' => 'CREATE INDEX IF NOT EXISTS idx_operations_project_id ON operations (project_id)',
            'idx_operations_type' => 'CREATE INDEX IF NOT EXISTS idx_operations_type ON operations (operation_type)',
            'idx_operations_status' => 'CREATE INDEX IF NOT EXISTS idx_operations_status ON operations (operation_status)',
            'idx_operations_created_at' => 'CREATE INDEX IF NOT EXISTS idx_operations_created_at ON operations (created_at)',
            'idx_operations_project_type' => 'CREATE INDEX IF NOT EXISTS idx_operations_project_type ON operations (project_id, operation_type)',
            'idx_operations_project_status_created' => 'CREATE INDEX IF NOT EXISTS idx_operations_project_status_created ON operations (project_id, operation_status, created_at)',

            'idx_operation_histories_changed_by' => 'CREATE INDEX IF NOT EXISTS idx_operation_histories_changed_by ON operation_status_histories (changed_by_project_participant_id)',
            'idx_operation_histories_created_at' => 'CREATE INDEX IF NOT EXISTS idx_operation_histories_created_at ON operation_status_histories (created_at)',
        ];

        foreach ($indexes as $sql) {
            DB::statement($sql);
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        $indexes = [
            'idx_operation_histories_created_at',
            'idx_operation_histories_changed_by',
            'idx_operations_project_status_created',
            'idx_operations_project_type',
            'idx_operations_created_at',
            'idx_operations_status',
            'idx_operations_type',
            'idx_operations_project_id',
            'idx_project_participant_wallets_created_at',
            'idx_project_participants_role_code',
            'idx_project_participants_counterparty_id',
            'idx_project_participants_project_id',
            'idx_projects_created_at',
            'idx_projects_is_active',
            'idx_projects_company_id',
            'idx_counterparties_company_role',
            'idx_counterparties_company_email',
            'idx_counterparties_company_role_code',
            'idx_counterparties_user_id',
            'idx_counterparties_company_id',
            'idx_companies_created_at',
            'idx_companies_is_active',
        ];

        foreach ($indexes as $index) {
            DB::statement("DROP INDEX IF EXISTS {$index}");
        }
    }
};
