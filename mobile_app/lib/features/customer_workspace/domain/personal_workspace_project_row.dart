class CustomerWalletSnapshot {
  final String personalBalance;
  final String personalReceived;
  final String personalEarned;
  final String accountableSpent;

  const CustomerWalletSnapshot({
    required this.personalBalance,
    required this.personalReceived,
    required this.personalEarned,
    required this.accountableSpent,
  });

  factory CustomerWalletSnapshot.fromJson(Map<String, dynamic> json) => CustomerWalletSnapshot(
        personalBalance: json['personal_balance'] as String? ?? '0.00',
        personalReceived: json['personal_received'] as String? ?? '0.00',
        personalEarned: json['personal_earned'] as String? ?? '0.00',
        accountableSpent: json['accountable_spent'] as String? ?? '0.00',
      );
}

class PersonalWorkspaceProjectRow {
  final int projectId;
  final String projectName;
  final int progressPercent;
  final bool projectIsActive;
  final int companyId;
  final String companyName;
  final CustomerWalletSnapshot wallet;
  final String participantLevel;
  final String participantProjectRoleCode;

  const PersonalWorkspaceProjectRow({
    required this.projectId,
    required this.projectName,
    required this.progressPercent,
    required this.projectIsActive,
    required this.companyId,
    required this.companyName,
    required this.wallet,
    this.participantLevel = '',
    this.participantProjectRoleCode = '',
  });

  /// ТЗ-05.3: из личного кабинета перевод создаёт только сотрудник 1-го порядка (роль в проекте EMPLOYEE).
  bool get canCreateTransferInPersonalWorkspace =>
      participantLevel.toLowerCase() == 'first' && participantProjectRoleCode == 'EMPLOYEE';

  factory PersonalWorkspaceProjectRow.fromJson(Map<String, dynamic> json) {
    final p = (json['project'] as Map).cast<String, dynamic>();
    final c = (json['company'] as Map).cast<String, dynamic>();
    final w = (json['my_wallet'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final part =
        (json['my_participation'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    bool asBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    return PersonalWorkspaceProjectRow(
      projectId: asInt(p['id']),
      projectName: (p['name'] ?? '').toString(),
      progressPercent: asInt(p['progress_percent']),
      projectIsActive: asBool(p['is_active']),
      companyId: asInt(c['id'] ?? json['company_id']),
      companyName: (c['name'] ?? json['company_name'] ?? '').toString(),
      wallet: CustomerWalletSnapshot.fromJson(w),
      participantLevel: (part['level'] ?? '').toString(),
      participantProjectRoleCode: (part['project_role_code'] ?? '').toString(),
    );
  }
}
