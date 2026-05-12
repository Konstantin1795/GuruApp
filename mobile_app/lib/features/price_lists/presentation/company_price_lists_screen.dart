import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_models.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/domain/company_workspace_context.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../../company_workspace/providers.dart';
import '../data/price_lists_repository.dart';
import '../providers.dart';
import 'create_edit_price_list_screen.dart';
import 'price_list_detail_screen.dart';

class CompanyPriceListsScreen extends ConsumerStatefulWidget {
  final int companyId;

  const CompanyPriceListsScreen({super.key, required this.companyId});

  @override
  ConsumerState<CompanyPriceListsScreen> createState() => _CompanyPriceListsScreenState();
}

class _CompanyPriceListsScreenState extends ConsumerState<CompanyPriceListsScreen> {
  final _searchCtrl = TextEditingController();
  String _submittedSearch = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    setState(() => _submittedSearch = _searchCtrl.text.trim());
  }

  void _fabMessage(PriceListLibraryFlags flags, BuildContext context) {
    final l10n = context.l10n;
    if (flags.createBlockedReason == 'partner_not_project_head') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.partnerNotProjectHeadPriceList)));
      return;
    }
    if (flags.createBlockedReason == 'partner_already_has_active_list') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.partnerAlreadyHasPriceList)));
    }
  }

  Future<void> _handleFabPress() async {
    final companyId = widget.companyId;
    final key = (companyId: companyId, search: _submittedSearch);
    final flags = ref.read(companyWorkspaceShellContextProvider(companyId)).valueOrNull?.priceLists;
    final canCreate = flags?.canCreateCompanyPriceList ?? true;
    if (!canCreate) {
      if (flags != null && mounted) _fabMessage(flags, context);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CreateEditPriceListScreen(companyId: companyId, priceListId: null),
      ),
    );
    ref.invalidate(companyPriceListsProvider(key));
    ref.invalidate(companyWorkspaceShellContextProvider(companyId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final companyId = widget.companyId;
    final key = (companyId: companyId, search: _submittedSearch);
    final async = ref.watch(companyPriceListsProvider(key));
    final ctxAsync = ref.watch(companyWorkspaceShellContextProvider(companyId));
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabel(ref, companyId, l10n);

    final flags = ctxAsync.valueOrNull?.priceLists;

    final canCreate = flags?.canCreateCompanyPriceList ?? true;
    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.priceListsTitle,
      floatingActionButton: FloatingActionButton(
        onPressed: _handleFabPress,
        backgroundColor: canCreate ? AppColors.accent : AppColors.surface,
        child: Icon(
          Icons.add_rounded,
          color: canCreate ? Colors.white : Colors.white.withValues(alpha: 0.35),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      labelText: l10n.search,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: _onSearch,
                      ),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: AppLoader()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text('$e', style: AppTextStyles.body.copyWith(color: AppColors.error)),
                ),
              ),
              data: (Paginated<PriceListListRow> page) {
                if (page.items.isEmpty) {
                  return RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: () async {
                      ref.invalidate(companyPriceListsProvider(key));
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.4,
                          child: AppEmptyState(
                            icon: Icons.request_quote_outlined,
                            title: l10n.priceListsEmpty,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async {
                    ref.invalidate(companyPriceListsProvider(key));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: page.items.length,
                    itemBuilder: (_, i) {
                      final row = page.items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          onTap: () async {
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => PriceListDetailScreen(
                                  companyId: companyId,
                                  priceListId: row.id,
                                ),
                              ),
                            );
                            ref.invalidate(companyPriceListsProvider(key));
                            ref.invalidate(companyWorkspaceShellContextProvider(companyId));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(row.name, style: AppTextStyles.bodyStrong),
                              const SizedBox(height: 6),
                              Text(
                                '${l10n.priceListCreator}: ${row.creatorDisplayName}',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${l10n.priceListGroupsCount}: ${row.groupsCount} · ${l10n.priceListPositionsCount}: ${row.positionsCount}',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
