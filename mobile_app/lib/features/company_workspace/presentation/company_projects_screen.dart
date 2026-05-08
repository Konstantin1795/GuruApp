import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_models.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../projects/domain/project.dart';
import '../../projects/providers.dart';

class CompanyProjectsState {
  final List<Project> items;
  final PaginationInfo? pagination;
  final bool isLoadingMore;

  const CompanyProjectsState({
    required this.items,
    required this.pagination,
    required this.isLoadingMore,
  });

  bool get hasMore => pagination?.hasMore ?? false;

  CompanyProjectsState copyWith({
    List<Project>? items,
    PaginationInfo? pagination,
    bool? isLoadingMore,
  }) =>
      CompanyProjectsState(
        items: items ?? this.items,
        pagination: pagination ?? this.pagination,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class CompanyProjectsController extends StateNotifier<AsyncValue<CompanyProjectsState>> {
  final int companyId;
  final Ref ref;

  CompanyProjectsController({required this.companyId, required this.ref})
      : super(
          const AsyncValue.loading(),
        ) {
    _loadFirstPage();
  }

  static const _perPage = 15;

  Future<void> _loadFirstPage() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(projectsRepositoryProvider);
      final page1 = await repo.listCompany(companyId: companyId, page: 1, perPage: _perPage);
      state = AsyncValue.data(
        CompanyProjectsState(
          items: page1.items,
          pagination: page1.pagination,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final repo = ref.read(projectsRepositoryProvider);
      final nextPage = (current.pagination?.page ?? 1) + 1;
      final res = await repo.listCompany(companyId: companyId, page: nextPage, perPage: _perPage);
      final merged = <Project>[...current.items, ...res.items];
      state = AsyncValue.data(
        CompanyProjectsState(
          items: merged,
          pagination: res.pagination,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      // Keep current list visible, but surface error via AsyncError with previous value.
      state = AsyncValue.error(e, st);
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() => _loadFirstPage();
}

final companyProjectsControllerProvider = StateNotifierProvider.family<
    CompanyProjectsController, AsyncValue<CompanyProjectsState>, int>((ref, companyId) {
  return CompanyProjectsController(companyId: companyId, ref: ref);
});

class CompanyProjectsScreen extends ConsumerWidget {
  final int companyId;
  const CompanyProjectsScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyProjectsControllerProvider(companyId));

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e is ApiException ? e.message : 'Failed to load projects.'),
              const SizedBox(height: 12),
              AppButton(
                label: 'Retry',
                onPressed: () =>
                    ref.read(companyProjectsControllerProvider(companyId).notifier).refresh(),
              ),
            ],
          ),
        ),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () => ref.read(companyProjectsControllerProvider(companyId).notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (data.items.isEmpty)
              const AppCard(
                child: Text('No projects yet.'),
              )
            else
              ...data.items.map(
                (p) => AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              'Progress: ${p.progressPercent}%',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                      if (!p.isActive)
                        Text('inactive',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (data.hasMore)
              AppButton(
                label: data.isLoadingMore ? 'Loading...' : 'Load more',
                onPressed: data.isLoadingMore
                    ? null
                    : () => ref
                        .read(companyProjectsControllerProvider(companyId).notifier)
                        .loadMore(),
              )
            else if (data.pagination != null && data.items.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Total: ${data.pagination!.total}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

