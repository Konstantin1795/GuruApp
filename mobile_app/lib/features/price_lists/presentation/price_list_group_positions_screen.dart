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
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../data/price_lists_repository.dart';
import '../providers.dart';
import 'create_edit_price_list_position_screen.dart';

class PriceListGroupPositionsScreen extends ConsumerWidget {
  final int companyId;
  final int priceListId;
  final int groupId;
  final String groupName;
  final bool canEdit;

  const PriceListGroupPositionsScreen({
    super.key,
    required this.companyId,
    required this.priceListId,
    required this.groupId,
    required this.groupName,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = (companyId: companyId, priceListId: priceListId, groupId: groupId, search: '');
    final async = ref.watch(priceListPositionsProvider(key));
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabel(ref, companyId, l10n);

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: groupName,
      subtitle: l10n.priceListPositions,
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => CreateEditPriceListPositionScreen(
                      companyId: companyId,
                      priceListId: priceListId,
                      groupId: groupId,
                      positionId: null,
                    ),
                  ),
                );
                ref.invalidate(priceListPositionsProvider(key));
                ref.invalidate(
                  priceListDetailProvider((companyId: companyId, priceListId: priceListId)),
                );
              },
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => Center(child: Text('$e', style: AppTextStyles.body.copyWith(color: AppColors.error))),
        data: (Paginated<PriceListPositionRow> page) {
          if (page.items.isEmpty) {
            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async => ref.invalidate(priceListPositionsProvider(key)),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.35,
                    child: AppEmptyState(icon: Icons.list_alt_outlined, title: l10n.priceListsEmpty),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async => ref.invalidate(priceListPositionsProvider(key)),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: page.items.length,
              itemBuilder: (_, i) {
                final p = page.items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    onTap: canEdit
                        ? () async {
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => CreateEditPriceListPositionScreen(
                                  companyId: companyId,
                                  priceListId: priceListId,
                                  groupId: groupId,
                                  positionId: p.id,
                                ),
                              ),
                            );
                            ref.invalidate(priceListPositionsProvider(key));
                            ref.invalidate(
                              priceListDetailProvider((companyId: companyId, priceListId: priceListId)),
                            );
                          }
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.serviceName, style: AppTextStyles.bodyStrong),
                        Text(
                          '${p.unit?.shortName ?? ''} · ${p.recipientUnitPrice} / ${p.customerUnitPrice}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          '${l10n.profitLabel}: ${p.profitAmount} · ${l10n.profitPercentLabel}: ${p.profitPercent ?? '—'}',
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
    );
  }
}
