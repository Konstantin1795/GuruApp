import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_provider.dart';
import '../../counterparties/providers.dart';
import '../../projects/providers.dart';
import '../domain/company_dashboard_stats.dart';

final companyDashboardStatsProvider =
    FutureProvider.family<CompanyDashboardStats, int>((ref, companyId) async {
  final cpRepo = ref.read(counterpartiesRepositoryProvider);
  final pjRepo = ref.read(projectsRepositoryProvider);

  final counterpartiesTotal = await cpRepo.countCompany(companyId: companyId);
  final projects = await pjRepo.listAllCompany(companyId: companyId);

  final locale = ref.watch(localeProvider);
  return CompanyDashboardStats.compute(
    projects: projects,
    counterpartiesTotal: counterpartiesTotal,
    now: DateTime.now(),
    locale: locale,
  );
});
