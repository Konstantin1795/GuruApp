import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_models.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_loader.dart';
import '../../counterparties/domain/counterparty.dart';
import '../../counterparties/providers.dart';

class CompanyCounterpartiesState {
  final List<Counterparty> items;
  final PaginationInfo? pagination;
  final bool isLoadingMore;
  final String query;

  const CompanyCounterpartiesState({
    required this.items,
    required this.pagination,
    required this.isLoadingMore,
    required this.query,
  });

  bool get hasMore => pagination?.hasMore ?? false;

  CompanyCounterpartiesState copyWith({
    List<Counterparty>? items,
    PaginationInfo? pagination,
    bool? isLoadingMore,
    String? query,
  }) =>
      CompanyCounterpartiesState(
        items: items ?? this.items,
        pagination: pagination ?? this.pagination,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        query: query ?? this.query,
      );
}

class CompanyCounterpartiesController
    extends StateNotifier<AsyncValue<CompanyCounterpartiesState>> {
  final int companyId;
  final Ref ref;

  CompanyCounterpartiesController({required this.companyId, required this.ref})
      : super(const AsyncValue.loading()) {
    _loadFirstPage();
  }

  static const _perPage = 15;

  Future<void> _loadFirstPage({String? query}) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(counterpartiesRepositoryProvider);
      final page1 = await repo.listCompany(
        companyId: companyId,
        page: 1,
        perPage: _perPage,
        query: query,
      );
      state = AsyncValue.data(
        CompanyCounterpartiesState(
          items: page1.items,
          pagination: page1.pagination,
          isLoadingMore: false,
          query: query?.trim() ?? '',
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
      final repo = ref.read(counterpartiesRepositoryProvider);
      final nextPage = (current.pagination?.page ?? 1) + 1;
      final res = await repo.listCompany(
        companyId: companyId,
        page: nextPage,
        perPage: _perPage,
        query: current.query,
      );
      final merged = <Counterparty>[...current.items, ...res.items];
      state = AsyncValue.data(
        CompanyCounterpartiesState(
          items: merged,
          pagination: res.pagination,
          isLoadingMore: false,
          query: current.query,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() => _loadFirstPage(query: state.valueOrNull?.query);

  Future<void> search(String query) => _loadFirstPage(query: query);

  Future<void> create({
    required String companyRoleCode,
    required String fullName,
    String? email,
  }) async {
    await ref.read(counterpartiesRepositoryProvider).createCompany(
          companyId: companyId,
          companyRoleCode: companyRoleCode,
          fullName: fullName,
          email: email,
        );
    // After create, show full list so the new counterparty is visible even if user had a search query.
    await _loadFirstPage(query: '');
  }
}

final companyCounterpartiesControllerProvider = StateNotifierProvider.family<
    CompanyCounterpartiesController,
    AsyncValue<CompanyCounterpartiesState>,
    int>((ref, companyId) {
  return CompanyCounterpartiesController(companyId: companyId, ref: ref);
});

class CompanyCounterpartiesScreen extends ConsumerStatefulWidget {
  final int companyId;
  final bool showHeader;
  const CompanyCounterpartiesScreen({
    super.key,
    required this.companyId,
    this.showHeader = true,
  });

  @override
  ConsumerState<CompanyCounterpartiesScreen> createState() =>
      _CompanyCounterpartiesScreenState();
}

class _CompanyCounterpartiesScreenState extends ConsumerState<CompanyCounterpartiesScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final l10n = context.l10n;
    final fullNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String role = kCompanyWorkspaceCounterpartyRoles.first;
    bool isSubmitting = false;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.addCounterparty),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppInput(
                  controller: fullNameCtrl,
                  label: l10n.counterpartyFullName,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                AppInput(
                  controller: emailCtrl,
                  label: l10n.counterpartyEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {},
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: InputDecoration(labelText: l10n.counterpartyRole),
                  items: kCompanyWorkspaceCounterpartyRoles
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(companyWorkspaceCounterpartyRoleLabelRu(r)),
                        ),
                      )
                      .toList(),
                  onChanged: isSubmitting ? null : (v) => role = v ?? role,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final fullName = fullNameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      if (fullName.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(l10n.counterpartyEnterName)),
                        );
                        return;
                      }
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(l10n.counterpartyEnterEmail)),
                        );
                        return;
                      }

                      setState(() => isSubmitting = true);
                      try {
                        await ref
                            .read(companyCounterpartiesControllerProvider(widget.companyId).notifier)
                            .create(companyRoleCode: role, fullName: fullName, email: email);
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (e) {
                        setState(() => isSubmitting = false);
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(e is ApiException ? e.message : l10n.counterpartyErrorCreate),
                          ),
                        );
                      }
                    },
              child: Text(isSubmitting ? '...' : l10n.create),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.counterpartyAdded)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyCounterpartiesControllerProvider(widget.companyId));

    final l10n = context.l10n;

    return state.when(
      loading: () => const AppLoader(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e is ApiException ? e.message : l10n.counterpartiesErrorLoad),
              const SizedBox(height: 12),
              AppButton(
                label: l10n.retry,
                onPressed: () => ref
                    .read(companyCounterpartiesControllerProvider(widget.companyId).notifier)
                    .refresh(),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        if (_searchCtrl.text != data.query) {
          _searchCtrl.text = data.query;
        }

        return RefreshIndicator(
          onRefresh: () => ref
              .read(companyCounterpartiesControllerProvider(widget.companyId).notifier)
              .refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.showHeader) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppInput(
                        controller: _searchCtrl,
                        label: l10n.counterpartySearch,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (v) => ref
                            .read(companyCounterpartiesControllerProvider(widget.companyId).notifier)
                            .search(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: AppButton(
                        label: l10n.add,
                        onPressed: () => _showCreateDialog(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (data.items.isEmpty)
                AppCard(child: Text(l10n.counterpartiesEmpty))
              else
                ...data.items.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.userEmail ??
                                      c.email ??
                                      c.userName ??
                                      c.fullName ??
                                      'Counterparty #${c.id}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.counterpartyRole}: ${companyWorkspaceCounterpartyRoleLabelRu(c.companyRole)}'
                                  '${c.userId != null ? '' : ' • invite'}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                          if (!c.isActive)
                            Text(
                              l10n.projectInactive,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              if (data.hasMore)
                AppButton(
                  label: data.isLoadingMore ? l10n.loading : l10n.loadMore,
                  onPressed: data.isLoadingMore
                      ? null
                      : () => ref
                          .read(companyCounterpartiesControllerProvider(widget.companyId).notifier)
                          .loadMore(),
                )
              else if (data.pagination != null && data.items.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.counterpartyTotal(data.pagination!.total),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

