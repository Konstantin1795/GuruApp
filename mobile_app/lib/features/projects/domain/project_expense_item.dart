class ProjectExpenseItemListRow {
  final int id;
  final int projectId;
  final String name;
  final bool markupEnabled;
  final String? markupPercent;
  final bool isActive;
  final int profitRecipientsCount;
  final int markupRecipientsCount;

  const ProjectExpenseItemListRow({
    required this.id,
    required this.projectId,
    required this.name,
    required this.markupEnabled,
    required this.markupPercent,
    required this.isActive,
    required this.profitRecipientsCount,
    required this.markupRecipientsCount,
  });

  factory ProjectExpenseItemListRow.fromJson(Map<String, dynamic> json) => ProjectExpenseItemListRow(
        id: json['id'] as int,
        projectId: json['project_id'] as int,
        name: json['name'] as String,
        markupEnabled: json['markup_enabled'] as bool? ?? false,
        markupPercent: json['markup_percent'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        profitRecipientsCount: (json['profit_recipients_count'] as num?)?.toInt() ?? 0,
        markupRecipientsCount: (json['markup_recipients_count'] as num?)?.toInt() ?? 0,
      );
}

class ProjectExpenseItemShare {
  final int counterpartyId;
  final String counterpartyName;
  final String percent;

  const ProjectExpenseItemShare({
    required this.counterpartyId,
    required this.counterpartyName,
    required this.percent,
  });

  factory ProjectExpenseItemShare.fromJson(Map<String, dynamic> json) => ProjectExpenseItemShare(
        counterpartyId: json['counterparty_id'] as int,
        counterpartyName: json['counterparty_name'] as String? ?? '',
        percent: json['percent'] as String? ?? '0.00',
      );

  Map<String, dynamic> toRequestJson() => {
        'counterparty_id': counterpartyId,
        'percent': percent,
      };
}

class ProjectExpenseItemDetail {
  final int id;
  final int projectId;
  final String name;
  final bool markupEnabled;
  final String? markupPercent;
  final bool isActive;
  final List<ProjectExpenseItemShare> profitShares;
  final List<ProjectExpenseItemShare> markupShares;

  const ProjectExpenseItemDetail({
    required this.id,
    required this.projectId,
    required this.name,
    required this.markupEnabled,
    required this.markupPercent,
    required this.isActive,
    required this.profitShares,
    required this.markupShares,
  });

  factory ProjectExpenseItemDetail.fromJson(Map<String, dynamic> json) => ProjectExpenseItemDetail(
        id: json['id'] as int,
        projectId: json['project_id'] as int,
        name: json['name'] as String,
        markupEnabled: json['markup_enabled'] as bool? ?? false,
        markupPercent: json['markup_percent'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        profitShares: (json['profit_shares'] as List<dynamic>? ?? [])
            .map((e) => ProjectExpenseItemShare.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        markupShares: (json['markup_shares'] as List<dynamic>? ?? [])
            .map((e) => ProjectExpenseItemShare.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class ExpenseItemRecipientOption {
  final int id;
  final String counterpartyName;

  const ExpenseItemRecipientOption({
    required this.id,
    required this.counterpartyName,
  });

  factory ExpenseItemRecipientOption.fromJson(Map<String, dynamic> json) => ExpenseItemRecipientOption(
        id: json['id'] as int,
        counterpartyName: json['counterparty_name'] as String? ?? '',
      );
}
