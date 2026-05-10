import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loader.dart';
import '../../auth/presentation/login_screen.dart' show LocaleSwitchButton;
import '../../auth/providers.dart';
import '../../company_workspace/presentation/transfers_screen.dart';
import '../../customer_workspace/domain/personal_workspace_project_row.dart';
import '../../operations/data/transfers_api.dart';
import '../providers.dart';

/// ТЗ-05.3: вкладка «Операции» личного кабинета исполнителя (перевод / отчёт-плейсхолдер).
class PersonalOperationsTab extends ConsumerWidget {
  const PersonalOperationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(performerWorkspaceDataProvider);

    return async.when(
      data: (data) => CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _OperationsTopBar(onWorkspaces: () => context.go('/workspaces'))),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Text(l10n.operationTypeTitle, style: AppTextStyles.screenTitle),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: AppCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                radius: AppRadii.xxl,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.swap_horiz, color: AppColors.accent),
                      title: Text(l10n.operationTransfer, style: AppTextStyles.bodyStrong),
                      subtitle: Text(
                        l10n.operationTransferDescription,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      onTap: () => _openTransferFlow(context, data.projects),
                    ),
                    ListTile(
                      leading: Icon(Icons.receipt_long_outlined, color: AppColors.textHint),
                      title: Text(l10n.operationReport, style: AppTextStyles.bodyStrong),
                      subtitle: Text(
                        l10n.operationReportSoon,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      enabled: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: Text(l10n.personalOperationsProjectsTitle, style: AppTextStyles.screenTitle),
            ),
          ),
          if (data.projects.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  l10n.personalWorkspaceEmpty,
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
              sliver: SliverList.separated(
                itemCount: data.projects.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final p = data.projects[i];
                  return AppCard(
                    onTap: () => _openProjectTransfers(context, p),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    radius: AppRadii.xxl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.projectName, style: AppTextStyles.cardTitle),
                        const SizedBox(height: 4),
                        Text(
                          p.companyName,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      loading: () => const Center(child: AppLoader()),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3l),
          child: Text(
            l10n.personalWorkspaceLoadError,
            style: AppTextStyles.body.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _openProjectTransfers(BuildContext context, PersonalWorkspaceProjectRow p) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TransfersScreen(
          apiScope: TransferApiScope.personal,
          companyId: p.companyId,
          projectId: p.projectId,
          projectName: p.projectName,
          canCreateTransfer: p.canCreateTransferInPersonalWorkspace,
        ),
      ),
    );
  }

  Future<void> _openTransferFlow(
    BuildContext context,
    List<PersonalWorkspaceProjectRow> projects,
  ) async {
    final l10n = context.l10n;
    final eligible = projects.where((p) => p.canCreateTransferInPersonalWorkspace).toList();
    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.personalOperationsNoTransferProjects)),
      );
      return;
    }

    PersonalWorkspaceProjectRow? chosen = eligible.length == 1 ? eligible.first : null;
    if (chosen == null && context.mounted) {
      chosen = await showModalBottomSheet<PersonalWorkspaceProjectRow>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(l10n.createTransfer, style: AppTextStyles.screenTitle),
                ),
                for (final p in eligible)
                  ListTile(
                    title: Text(p.projectName, style: AppTextStyles.bodyStrong),
                    subtitle: Text(p.companyName),
                    onTap: () => Navigator.of(ctx).pop(p),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      );
    }

    if (chosen == null || !context.mounted) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreateTransferScreen(
          apiScope: TransferApiScope.personal,
          companyId: chosen!.companyId,
          projectId: chosen.projectId,
          projectName: chosen.projectName,
        ),
      ),
    );
  }
}

class _OperationsTopBar extends ConsumerWidget {
  final VoidCallback onWorkspaces;

  const _OperationsTopBar({required this.onWorkspaces});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onWorkspaces,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
            ),
            icon: const Icon(Icons.menu_rounded),
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.bodyStrong,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
          const LocaleSwitchButton(),
        ],
      ),
    );
  }
}
