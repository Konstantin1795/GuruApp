import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../providers.dart';
import 'create_edit_project_expense_item_screen.dart';

class ProjectExpenseItemsScreen extends ConsumerWidget {
  final int companyId;
  final int projectId;
  final String projectName;
  final bool canManage;

  const ProjectExpenseItemsScreen({
    super.key,
    required this.companyId,
    required this.projectId,
    required this.projectName,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = (companyId: companyId, projectId: projectId);
    final async = ref.watch(projectExpenseItemsProvider(key));
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabel(ref, companyId, l10n);

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.projectExpenseArticles,
      subtitle: projectName,
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => CreateEditProjectExpenseItemScreen(
                      companyId: companyId,
                      projectId: projectId,
                      expenseItemId: null,
                      canManage: true,
                    ),
                  ),
                );
                ref.invalidate(projectExpenseItemsProvider(key));
              },
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('$e', style: AppTextStyles.body.copyWith(color: AppColors.error), textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async {
                ref.invalidate(projectExpenseItemsProvider(key));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.45,
                    child: AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: l10n.expenseItemsEmptyState,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async {
              ref.invalidate(projectExpenseItemsProvider(key));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final row = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => CreateEditProjectExpenseItemScreen(
                            companyId: companyId,
                            projectId: projectId,
                            expenseItemId: row.id,
                            canManage: canManage,
                          ),
                        ),
                      );
                      ref.invalidate(projectExpenseItemsProvider(key));
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(row.name, style: AppTextStyles.bodyStrong)),
                            if (canManage)
                              Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          row.markupEnabled
                              ? '${l10n.markupOnExpenseItem}: ${row.markupPercent ?? '—'}%'
                              : l10n.markupDisabledLabel,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${l10n.profitShares}: ${row.profitRecipientsCount}',
                          style: AppTextStyles.caption,
                        ),
                        if (row.markupEnabled) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${l10n.markupShares}: ${row.markupRecipientsCount}',
                            style: AppTextStyles.caption,
                          ),
                        ],
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
