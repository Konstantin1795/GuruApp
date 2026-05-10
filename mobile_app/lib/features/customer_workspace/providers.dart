import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../projects/providers.dart';
import 'data/personal_companies_api.dart';
import 'data/personal_companies_repository.dart';
import 'domain/personal_company_row.dart';
import 'domain/personal_workspace_project_row.dart';

final personalCompaniesApiProvider = Provider<PersonalCompaniesApi>(
  (ref) => PersonalCompaniesApi(ref.watch(apiClientProvider)),
);

final personalCompaniesRepositoryProvider = Provider<PersonalCompaniesRepository>(
  (ref) => PersonalCompaniesRepository(ref.watch(personalCompaniesApiProvider)),
);

class CustomerWorkspaceData {
  final List<PersonalCompanyRow> companies;
  final List<PersonalWorkspaceProjectRow> projects;

  const CustomerWorkspaceData({
    required this.companies,
    required this.projects,
  });
}

/// Customer role only; used by home, company list, and project list screens.
final customerWorkspaceDataProvider = FutureProvider.autoDispose<CustomerWorkspaceData>((ref) async {
  final companiesRepo = ref.read(personalCompaniesRepositoryProvider);
  final projectsRepo = ref.read(projectsRepositoryProvider);
  final companies = await companiesRepo.listAll(workspaceRole: 'customer');
  final projects = await projectsRepo.listAllPersonalWorkspaceRows(workspaceRole: 'customer');

  final nameByCompanyId = <int, String>{};
  for (final p in projects) {
    final n = p.companyName.trim();
    if (n.isEmpty) continue;
    nameByCompanyId.putIfAbsent(p.companyId, () => n);
  }

  final merged = companies
      .map((c) => c.withFallbackName(nameByCompanyId[c.id]))
      .toList(growable: false);

  return CustomerWorkspaceData(companies: merged, projects: projects);
});
