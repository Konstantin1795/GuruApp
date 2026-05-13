import 'project_workspace_scope.dart';

class ProjectSummaryHeader {
  final int id;
  final String name;
  final int companyId;
  final String companyName;
  final String? address;
  final String? deliveryDate;
  final int progressPercent;
  final bool isActive;

  const ProjectSummaryHeader({
    required this.id,
    required this.name,
    required this.companyId,
    required this.companyName,
    this.address,
    this.deliveryDate,
    required this.progressPercent,
    required this.isActive,
  });

  factory ProjectSummaryHeader.fromJson(Map<String, dynamic> json) => ProjectSummaryHeader(
        id: json['id'] as int,
        name: json['name'] as String,
        companyId: json['company_id'] as int,
        companyName: json['company_name'] as String? ?? '',
        address: json['address'] as String?,
        deliveryDate: json['delivery_date'] as String?,
        progressPercent: (json['progress_percent'] as num?)?.toInt() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class ProjectSummaryMetrics {
  final String incomeTotal;
  final String expenseTotal;
  final String projectBalance;

  const ProjectSummaryMetrics({
    required this.incomeTotal,
    required this.expenseTotal,
    required this.projectBalance,
  });

  factory ProjectSummaryMetrics.fromJson(Map<String, dynamic> json) => ProjectSummaryMetrics(
        incomeTotal: json['income_total'] as String? ?? '0.00',
        expenseTotal: json['expense_total'] as String? ?? '0.00',
        projectBalance: json['project_balance'] as String? ?? '0.00',
      );
}

class ProjectSummaryVisibility {
  final bool canViewInternalMetrics;
  final bool canViewParticipants;
  final bool canCreateIncome;
  final bool canCreateTransfer;
  final bool canCreateReport;
  final bool canViewExpenseItems;
  final bool canManageExpenseItems;
  final bool canViewProjectPriceLists;
  final bool canManageProjectPriceListAttachments;

  const ProjectSummaryVisibility({
    required this.canViewInternalMetrics,
    required this.canViewParticipants,
    required this.canCreateIncome,
    required this.canCreateTransfer,
    required this.canCreateReport,
    required this.canViewExpenseItems,
    required this.canManageExpenseItems,
    required this.canViewProjectPriceLists,
    required this.canManageProjectPriceListAttachments,
  });

  factory ProjectSummaryVisibility.fromJson(Map<String, dynamic> json) => ProjectSummaryVisibility(
        canViewInternalMetrics: json['can_view_internal_metrics'] as bool? ?? false,
        canViewParticipants: json['can_view_participants'] as bool? ?? false,
        canCreateIncome: json['can_create_income'] as bool? ?? false,
        canCreateTransfer: json['can_create_transfer'] as bool? ?? false,
        canCreateReport: json['can_create_report'] as bool? ?? false,
        canViewExpenseItems: json['can_view_expense_items'] as bool? ?? false,
        canManageExpenseItems: json['can_manage_expense_items'] as bool? ?? false,
        canViewProjectPriceLists: json['can_view_project_price_lists'] as bool? ?? false,
        canManageProjectPriceListAttachments:
            json['can_manage_project_price_list_attachments'] as bool? ?? false,
      );
}

class ProjectSummary {
  final ProjectSummaryHeader project;
  final ProjectSummaryMetrics metrics;
  final ProjectSummaryVisibility visibility;

  const ProjectSummary({
    required this.project,
    required this.metrics,
    required this.visibility,
  });

  factory ProjectSummary.fromJson(Map<String, dynamic> json) => ProjectSummary(
        project: ProjectSummaryHeader.fromJson((json['project'] as Map).cast<String, dynamic>()),
        metrics: ProjectSummaryMetrics.fromJson((json['metrics'] as Map).cast<String, dynamic>()),
        visibility: ProjectSummaryVisibility.fromJson((json['visibility'] as Map).cast<String, dynamic>()),
      );
}

extension ProjectSummaryHeaderToWorkspaceKey on ProjectSummaryHeader {
  ProjectWorkspaceKey workspaceKey(ProjectWorkspaceScope scope) => ProjectWorkspaceKey(
        projectId: id,
        companyId: scope == ProjectWorkspaceScope.company ? companyId : null,
        scope: scope,
      );
}
