<?php

namespace Tests\Feature;

use Tests\TestCase;

final class ProtectedApiRoutesTest extends TestCase
{
    public function test_company_project_internal_metrics_requires_authentication(): void
    {
        $response = $this->getJson('/api/company-workspace/1/projects/1/internal-metrics');

        $response->assertUnauthorized();
    }

    public function test_personal_project_internal_metrics_requires_authentication(): void
    {
        $response = $this->getJson('/api/personal-workspace/projects/1/internal-metrics');

        $response->assertUnauthorized();
    }

    public function test_unified_operations_history_company_requires_authentication(): void
    {
        $response = $this->getJson('/api/company-workspace/1/operations/history');

        $response->assertUnauthorized();
    }

    public function test_unified_operations_history_personal_requires_authentication(): void
    {
        $response = $this->getJson('/api/personal-workspace/operations/history');

        $response->assertUnauthorized();
    }

    public function test_company_project_expense_items_requires_authentication(): void
    {
        $response = $this->getJson('/api/company-workspace/1/projects/1/expense-items');

        $response->assertUnauthorized();
    }
}
