class ProjectInternalMetrics {
  final String participantsAccountableBalance;
  final String projectDebtToCounterparties;
  final String overpaymentOrMissingReports;
  final String projectBalance;

  const ProjectInternalMetrics({
    required this.participantsAccountableBalance,
    required this.projectDebtToCounterparties,
    required this.overpaymentOrMissingReports,
    required this.projectBalance,
  });

  factory ProjectInternalMetrics.fromJson(Map<String, dynamic> json) {
    final m = (json['metrics'] as Map).cast<String, dynamic>();
    return ProjectInternalMetrics(
      participantsAccountableBalance: m['participants_accountable_balance'] as String? ?? '0.00',
      projectDebtToCounterparties: m['project_debt_to_counterparties'] as String? ?? '0.00',
      overpaymentOrMissingReports: m['overpayment_or_missing_reports'] as String? ?? '0.00',
      projectBalance: m['project_balance'] as String? ?? '0.00',
    );
  }
}
