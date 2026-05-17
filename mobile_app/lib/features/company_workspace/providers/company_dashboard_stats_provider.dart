import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_provider.dart';
import '../../counterparties/providers.dart';
import '../../projects/providers.dart';
import '../domain/company_dashboard_stats.dart';
import '../providers.dart';

typedef CompanyDashboardStatsArgs = ({int companyId, String? selectedMonth});

final companyDashboardStatsProvider =
    FutureProvider.autoDispose.family<CompanyDashboardStats, CompanyDashboardStatsArgs>((ref, args) async {
  final cpRepo = ref.read(counterpartiesRepositoryProvider);
  final pjRepo = ref.read(projectsRepositoryProvider);
  final api = ref.read(companyWorkspaceApiProvider);
  final locale = ref.watch(localeProvider);

  final counterpartiesTotal = await cpRepo.countCompany(companyId: args.companyId);
  final projects = await pjRepo.listAllCompany(companyId: args.companyId);

  Map<String, dynamic>? analytics;
  try {
    analytics = await api.getDashboardAnalytics(
      companyId: args.companyId,
      month: args.selectedMonth,
    );
  } catch (_) {
    analytics = null;
  }

  return CompanyDashboardStats.merge(
    projects: projects,
    counterpartiesTotal: counterpartiesTotal,
    now: DateTime.now(),
    locale: locale,
    analytics: analytics,
  );
});
