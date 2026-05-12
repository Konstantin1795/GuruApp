import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../providers.dart';
import 'create_edit_price_list_group_screen.dart';
import 'create_edit_price_list_screen.dart';
import 'price_list_group_positions_screen.dart';

class PriceListDetailScreen extends ConsumerWidget {
  final int companyId;
  final int priceListId;

  const PriceListDetailScreen({
    super.key,
    required this.companyId,
    required this.priceListId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = (companyId: companyId, priceListId: priceListId);
    final async = ref.watch(priceListDetailProvider(key));
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabel(ref, companyId, l10n);

    return async.when(
      loading: () => AppScaffold(
        headerUserName: userName.isEmpty ? null : userName,
        headerRoleLabel: roleLabel,
        title: l10n.priceListsTitle,
        body: const Center(child: AppLoader()),
      ),
      error: (e, _) => AppScaffold(
        headerUserName: userName.isEmpty ? null : userName,
        headerRoleLabel: roleLabel,
        title: l10n.priceListsTitle,
        body: Center(child: Text('$e', style: AppTextStyles.body.copyWith(color: AppColors.error))),
      ),
      data: (d) => AppScaffold(
        headerUserName: userName.isEmpty ? null : userName,
        headerRoleLabel: roleLabel,
        title: d.name,
        actions: [
          if (d.canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => CreateEditPriceListScreen(
                      companyId: companyId,
                      priceListId: priceListId,
                    ),
                  ),
                );
                ref.invalidate(priceListDetailProvider(key));
              },
            ),
          if (d.canEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.deletePriceList),
                    content: Text(l10n.deletePriceListConfirm),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                final repo = ref.read(priceListsRepositoryProvider);
                final res = await repo.deletePriceList(companyId: companyId, priceListId: priceListId);
                final detached = (res['detached_projects_count'] as num?)?.toInt() ?? 0;
                if (context.mounted && detached > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.priceListDeleteProjectsWarning(detached))),
                  );
                }
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
        floatingActionButton: d.canEdit
            ? FloatingActionButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => CreateEditPriceListGroupScreen(
                        companyId: companyId,
                        priceListId: priceListId,
                        groupId: null,
                        initialName: '',
                      ),
                    ),
                  );
                  ref.invalidate(priceListDetailProvider(key));
                },
                backgroundColor: AppColors.accent,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              )
            : null,
        body: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(priceListDetailProvider(key));
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                '${l10n.priceListCreator}: ${d.creatorDisplayName}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.priceListGroups, style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              if (d.groups.isEmpty)
                Text(
                  l10n.priceListsEmpty,
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                )
              else
                ...d.groups.map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => PriceListGroupPositionsScreen(
                              companyId: companyId,
                              priceListId: priceListId,
                              groupId: g.id,
                              groupName: g.name,
                              canEdit: d.canEdit,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.name, style: AppTextStyles.bodyStrong),
                                Text(
                                  '${l10n.priceListPositionsCount}: ${g.positionsCount}',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
