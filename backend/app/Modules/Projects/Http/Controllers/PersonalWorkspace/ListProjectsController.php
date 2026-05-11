<?php

namespace App\Modules\Projects\Http\Controllers\PersonalWorkspace;

use App\Modules\Operations\Enums\OperationStatus;
use App\Modules\Projects\Http\Resources\PersonalProjectResource;
use App\Modules\Workspaces\Support\PersonalWorkspaceRoleFilter;
use App\Support\Http\ApiResponse;
use App\Support\Http\Pagination\PaginatedResourceResponse;
use App\Support\Http\Pagination\Pagination;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

final class ListProjectsController
{
    public function __invoke(Request $request)
    {
        $p = Pagination::fromRequest($request);
        $userId = (int) $request->user()->id;

        $roleFilter = PersonalWorkspaceRoleFilter::fromQuery($request->query('workspace_role'));

        $incomeTotals = DB::table('income_operations')
            ->select([
                'customer_project_participant_id',
                DB::raw('SUM(CAST(amount AS DECIMAL(18,2))) as income_received_total'),
            ])
            ->whereIn('operation_status', [
                OperationStatus::CUSTOMER_APPROVAL->value,
                OperationStatus::WAITING_24_HOURS->value,
                OperationStatus::COMPLETED->value,
            ])
            ->whereNotNull('wallets_applied_at')
            ->groupBy('customer_project_participant_id');

        $query = DB::table('project_participants')
            ->select([
                'projects.id as project_id',
                'projects.name as project_name',
                'projects.progress_percent as progress_percent',
                'projects.is_active as is_active',
                'companies.id as company_id',
                'companies.name as company_name',
                'project_participants.level as participant_level',
                'project_participants.project_role_code as participant_project_role_code',
                'project_participant_wallets.personal_balance as wallet_personal_balance',
                'project_participant_wallets.personal_received as wallet_personal_received',
                'project_participant_wallets.personal_earned as wallet_personal_earned',
                'project_participant_wallets.accountable_spent as wallet_accountable_spent',
                'project_participant_wallets.accountable_balance as wallet_accountable_balance',
                DB::raw('COALESCE(inc_tot.income_received_total, 0) as income_received_total'),
            ])
            ->join('counterparties', 'counterparties.id', '=', 'project_participants.counterparty_id')
            ->join('projects', 'projects.id', '=', 'project_participants.project_id')
            ->join('companies', 'companies.id', '=', 'projects.company_id')
            ->leftJoin(
                'project_participant_wallets',
                'project_participant_wallets.project_participant_id',
                '=',
                'project_participants.id',
            )
            ->leftJoinSub($incomeTotals, 'inc_tot', function ($join): void {
                $join->on('inc_tot.customer_project_participant_id', '=', 'project_participants.id');
            })
            ->where('counterparties.user_id', $userId)
            ->where('counterparties.is_active', true)
            ->whereIn('counterparties.company_role_code', $roleFilter)
            ->where('project_participants.is_active', true)
            ->orderByDesc('projects.id')
            ->distinct('projects.id');

        $paginator = $query->paginate(
            perPage: $p['per_page'],
            page: $p['page'],
        );

        $items = collect($paginator->items());
        $collection = PersonalProjectResource::collection($items);

        return ApiResponse::ok(PaginatedResourceResponse::fromPaginator($collection, $paginator));
    }
}
