import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../customer_workspace/domain/personal_company_row.dart';
import '../customer_workspace/domain/personal_workspace_project_row.dart';
import '../customer_workspace/providers.dart';
import '../projects/providers.dart';
import 'data/personal_income_api.dart';
import 'domain/personal_income_month.dart';

final personalIncomeApiProvider = Provider<PersonalIncomeApi>(
  (ref) => PersonalIncomeApi(ref.watch(apiClientProvider)),
);

class PerformerWorkspaceData {
  final List<PersonalCompanyRow> companies;
  final List<PersonalWorkspaceProjectRow> projects;
  final List<PersonalIncomeMonth> incomeMonths;
  final String incomeTotalForPeriod;

  const PerformerWorkspaceData({
    required this.companies,
    required this.projects,
    required this.incomeMonths,
    required this.incomeTotalForPeriod,
  });
}

/// Employee / supplier / contractor personal workspace (no customer role mix-in).
final performerWorkspaceDataProvider = FutureProvider.autoDispose<PerformerWorkspaceData>((ref) async {
  final companiesRepo = ref.read(personalCompaniesRepositoryProvider);
  final projectsRepo = ref.read(projectsRepositoryProvider);
  final incomeApi = ref.read(personalIncomeApiProvider);

  final results = await Future.wait([
    companiesRepo.listAll(workspaceRole: 'performer'),
    projectsRepo.listAllPersonalWorkspaceRows(workspaceRole: 'performer'),
  ]);

  final companies = results[0] as List<PersonalCompanyRow>;
  final projects = results[1] as List<PersonalWorkspaceProjectRow>;

  List<PersonalIncomeMonth> incomeMonths = const [];
  String incomeTotal = '0.00';
  try {
    final incomeJson = await incomeApi.incomeByMonth(months: 6);
    final rawData = incomeJson['data'];
    final payload = rawData is Map ? rawData.cast<String, dynamic>() : <String, dynamic>{};
    final monthsRaw = (payload['months'] as List<dynamic>?) ?? const [];
    incomeMonths = monthsRaw
        .map((e) => PersonalIncomeMonth.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
    incomeTotal = (payload['total_for_period'] ?? '0.00').toString();
  } catch (_) {
    // Income endpoint is optional for the shell; companies/projects still show.
  }

  final nameByCompanyId = <int, String>{};
  for (final p in projects) {
    final n = p.companyName.trim();
    if (n.isEmpty) continue;
    nameByCompanyId.putIfAbsent(p.companyId, () => n);
  }

  final merged = companies.map((c) => c.withFallbackName(nameByCompanyId[c.id])).toList(growable: false);

  return PerformerWorkspaceData(
    companies: merged,
    projects: projects,
    incomeMonths: incomeMonths,
    incomeTotalForPeriod: incomeTotal,
  );
});
