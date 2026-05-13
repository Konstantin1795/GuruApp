import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import 'data/participant_wallet_api.dart';
import 'data/participant_wallet_repository.dart';
import 'data/project_participants_api.dart';
import 'data/project_participants_repository.dart';
import 'data/project_expense_items_api.dart';
import 'data/project_expense_items_repository.dart';
import 'data/projects_api.dart';
import 'data/projects_repository.dart';
import 'domain/project_expense_item.dart';
import 'domain/project_internal_metrics.dart';
import 'domain/project_summary.dart';
import 'domain/project_workspace_scope.dart';

final projectsApiProvider = Provider<ProjectsApi>((ref) => ProjectsApi(ref.watch(apiClientProvider)));

final projectsRepositoryProvider =
    Provider<ProjectsRepository>((ref) => ProjectsRepository(ref.watch(projectsApiProvider)));

final projectParticipantsApiProvider = Provider<ProjectParticipantsApi>(
  (ref) => ProjectParticipantsApi(ref.watch(apiClientProvider)),
);

final projectParticipantsRepositoryProvider = Provider<ProjectParticipantsRepository>(
  (ref) => ProjectParticipantsRepository(ref.watch(projectParticipantsApiProvider)),
);

final participantWalletApiProvider = Provider<ParticipantWalletApi>(
  (ref) => ParticipantWalletApi(ref.watch(apiClientProvider)),
);

final participantWalletRepositoryProvider = Provider<ParticipantWalletRepository>(
  (ref) => ParticipantWalletRepository(ref.watch(participantWalletApiProvider)),
);

final projectExpenseItemsApiProvider = Provider<ProjectExpenseItemsApi>(
  (ref) => ProjectExpenseItemsApi(ref.watch(apiClientProvider)),
);

final projectExpenseItemsRepositoryProvider = Provider<ProjectExpenseItemsRepository>(
  (ref) => ProjectExpenseItemsRepository(ref.watch(projectExpenseItemsApiProvider)),
);

/// Список статей расходов проекта (ТЗ-10A): только GET через API; права и `can_manage` — на сервере.
final projectExpenseItemsProvider =
    FutureProvider.family<List<ProjectExpenseItemListRow>, ({int companyId, int projectId})>((ref, key) async {
  return ref.read(projectExpenseItemsRepositoryProvider).list(
        companyId: key.companyId,
        projectId: key.projectId,
      );
});

final projectExpenseItemDetailProvider =
    FutureProvider.family<ProjectExpenseItemDetail, ({int companyId, int projectId, int expenseItemId})>(
        (ref, key) async {
  return ref.read(projectExpenseItemsRepositoryProvider).getDetail(
        companyId: key.companyId,
        projectId: key.projectId,
        expenseItemId: key.expenseItemId,
      );
});

final projectExpenseItemRecipientsProvider = FutureProvider.family<
    List<ExpenseItemRecipientOption>,
    ({
      int companyId,
      int projectId,
      String search,
    })>((ref, key) async {
  return ref.read(projectExpenseItemsRepositoryProvider).recipients(
        companyId: key.companyId,
        projectId: key.projectId,
        search: key.search.isEmpty ? null : key.search,
      );
});

final projectSummaryProvider =
    FutureProvider.family<ProjectSummary, ProjectWorkspaceKey>((ref, key) async {
  return ref.read(projectsRepositoryProvider).getProjectSummary(key);
});

final projectInternalMetricsProvider =
    FutureProvider.family<ProjectInternalMetrics?, ProjectWorkspaceKey>((ref, key) async {
  try {
    return await ref.read(projectsRepositoryProvider).getProjectInternalMetrics(key);
  } on ApiException catch (e) {
    if (e.statusCode == 403) return null;
    rethrow;
  }
});

