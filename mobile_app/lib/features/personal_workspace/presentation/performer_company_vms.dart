import '../../../l10n/gen/app_localizations.dart';
import '../../customer_workspace/domain/personal_company_row.dart';
import '../../customer_workspace/domain/personal_workspace_project_row.dart';
import '../../customer_workspace/presentation/money_format.dart';

String companyRoleLabel(AppLocalizations l10n, String code) {
  switch (code) {
    case 'EMPLOYEE':
      return l10n.roleEmployee;
    case 'SUPPLIER':
      return l10n.roleSupplier;
    case 'CONTRACTOR':
      return l10n.roleContractor;
    default:
      return code;
  }
}

class PerformerCompanyVm {
  final PersonalCompanyRow company;
  final String balance;
  final String received;
  final String earned;
  final String roleLabel;
  final double earnedSort;

  PerformerCompanyVm({
    required this.company,
    required this.balance,
    required this.received,
    required this.earned,
    required this.roleLabel,
    required this.earnedSort,
  });
}

List<PerformerCompanyVm> buildPerformerCompanyVms(
  List<PersonalCompanyRow> companies,
  List<PersonalWorkspaceProjectRow> projects,
  AppLocalizations l10n,
  String localeName,
) {
  final byCompany = <int, ({double b, double r, double e})>{};
  for (final p in projects) {
    final cur = byCompany[p.companyId] ?? (b: 0.0, r: 0.0, e: 0.0);
    final nb = cur.b + parseDecimalMoney(p.wallet.personalBalance);
    final nr = cur.r + parseDecimalMoney(p.wallet.personalReceived);
    final ne = cur.e + parseDecimalMoney(p.wallet.personalEarned);
    byCompany[p.companyId] = (b: nb, r: nr, e: ne);
  }

  final out = <PerformerCompanyVm>[];
  for (final c in companies) {
    final agg = byCompany[c.id] ?? (b: 0.0, r: 0.0, e: 0.0);
    final sortKey = agg.e + agg.r;
    out.add(
      PerformerCompanyVm(
        company: c,
        balance: formatMoneyDisplay(agg.b.toStringAsFixed(2), localeName),
        received: formatMoneyDisplay(agg.r.toStringAsFixed(2), localeName),
        earned: formatMoneyDisplay(agg.e.toStringAsFixed(2), localeName),
        roleLabel: companyRoleLabel(l10n, c.companyRole),
        earnedSort: sortKey,
      ),
    );
  }
  out.sort((a, b) => b.earnedSort.compareTo(a.earnedSort));
  return out;
}
