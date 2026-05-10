import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_models.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_loader.dart';
import '../../counterparties/providers.dart';
import '../../projects/domain/project.dart';
import '../../projects/providers.dart';
import 'project_participants_screen.dart';

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

  Future<void> create({
    required String name,
    required int customerCounterpartyId,
  }) async {
    await ref.read(projectsRepositoryProvider).createCompany(
          companyId: companyId,
          name: name,
          customerCounterpartyId: customerCounterpartyId,
        );
    await refresh();
  }
}

final companyProjectsControllerProvider = StateNotifierProvider.family<
    CompanyProjectsController, AsyncValue<CompanyProjectsState>, int>((ref, companyId) {
  return CompanyProjectsController(companyId: companyId, ref: ref);
});

/// Общий диалог создания проекта (дашборд «+», экран Projects).
Future<bool?> showCompanyCreateProjectDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int companyId,
  bool autofocusProjectName = false,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);

  final customers = await ref.read(counterpartiesRepositoryProvider).fetchCustomersOnly(
        companyId: companyId,
        page: 1,
        perPage: 50,
      );

  if (!context.mounted) return false;
  if (customers.isEmpty) {
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.projectNoCustomer)),
    );
    return false;
  }

  final nameCtrl = TextEditingController();
  var selected = customers.first;
  bool isSubmitting = false;

  final created = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(ctx.l10n.createProject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppInput(
              controller: nameCtrl,
              label: ctx.l10n.projectNameLabel,
              autofocus: autofocusProjectName,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: selected.id,
              decoration: InputDecoration(labelText: ctx.l10n.projectCustomerLabel),
              items: customers
                  .map(
                    (c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(
                        c.pickerDisplayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: isSubmitting
                  ? null
                  : (v) {
                      final next = customers.firstWhere((c) => c.id == v);
                      setState(() => selected = next);
                    },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.cancel),
          ),
          TextButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(ctx.l10n.projectNameLabel)),
                      );
                      return;
                    }
                    setState(() => isSubmitting = true);
                    try {
                      await ref.read(companyProjectsControllerProvider(companyId).notifier).create(
                            name: name,
                            customerCounterpartyId: selected.id,
                          );
                      if (ctx.mounted) Navigator.of(ctx).pop(true);
                    } catch (e) {
                      setState(() => isSubmitting = false);
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            e is ApiException ? e.message : ctx.l10n.projectErrorCreate,
                          ),
                        ),
                      );
                    }
                  },
            child: Text(isSubmitting ? '...' : ctx.l10n.create),
          ),
        ],
      ),
    ),
  );

  return created;
}

class CompanyProjectsScreen extends ConsumerWidget {
  final int companyId;
  final bool showCreateButton;
  const CompanyProjectsScreen({
    super.key,
    required this.companyId,
    this.showCreateButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyProjectsControllerProvider(companyId));

    return state.when(
      loading: () => const AppLoader(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e is ApiException ? e.message : context.l10n.projectsErrorLoad),
              const SizedBox(height: 12),
              AppButton(
                label: context.l10n.retry,
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
            if (showCreateButton) ...[
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: context.l10n.createProject,
                      icon: Icons.add,
                      onPressed: () async {
                        final created = await showCompanyCreateProjectDialog(
                          context: context,
                          ref: ref,
                          companyId: companyId,
                          autofocusProjectName: false,
                        );
                        if (created == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.projectCreated)),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (data.items.isEmpty)
              AppCard(child: Text(context.l10n.projectsEmpty))
            else
              ...data.items.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProjectParticipantsScreen(
                          project: p,
                          companyId: companyId,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                context.l10n.projectProgress(p.progressPercent),
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        if (!p.isActive) ...[
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.projectInactive,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (data.hasMore)
              AppButton(
                label: data.isLoadingMore ? context.l10n.loading : context.l10n.loadMore,
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
                    context.l10n.projectTotal(data.pagination!.total),
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

