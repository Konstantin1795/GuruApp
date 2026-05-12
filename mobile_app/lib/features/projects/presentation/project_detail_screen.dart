import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../../company_workspace/presentation/project_participants_screen.dart';
import '../../company_workspace/presentation/transfers_screen.dart';
import '../../customer_workspace/presentation/money_format.dart';
import '../../operations/data/transfers_api.dart';
import '../../operations/presentation/aggregated_operations_history_screen.dart';
import '../domain/project.dart';
import '../domain/project_summary.dart';
import '../domain/project_workspace_scope.dart';
import '../../price_lists/presentation/project_price_lists_screen.dart';
import '../providers.dart';
import 'project_expense_items_screen.dart';

/// Экран проекта (ТЗ-07): метрики, разделы, переход к участникам и операциям.
///
/// Суммы и балансы только отображаются из API (`ProjectSummary` / metrics); не пересчитывать
/// кошельки на клиенте — иначе расхождение с сервером и риск перед REPORT.
class ProjectDetailScreen extends ConsumerWidget {
  final ProjectWorkspaceKey workspaceKey;
  final String? titleFallback;

  const ProjectDetailScreen({
    super.key,
    required this.workspaceKey,
    this.titleFallback,
  });

  bool get _usesCompanyEndpoints => workspaceKey.scope == ProjectWorkspaceScope.company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectSummaryProvider(workspaceKey));
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = _usesCompanyEndpoints && workspaceKey.companyId != null
        ? companyWorkspaceHeaderRoleLabel(ref, workspaceKey.companyId!, l10n)
        : l10n.personalWorkspaceTitle;

    return async.when(
      loading: () => AppScaffold(
        headerUserName: userName.isEmpty ? null : userName,
        headerRoleLabel: roleLabel,
        title: titleFallback ?? l10n.projectDetailTitle,
        body: const Center(child: AppLoader()),
      ),
      error: (e, _) => AppScaffold(
        headerUserName: userName.isEmpty ? null : userName,
        headerRoleLabel: roleLabel,
        title: titleFallback ?? l10n.projectDetailTitle,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              e.toString(),
              style: AppTextStyles.body.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (summary) => AppScaffold(
        headerUserName: userName.isEmpty ? null : userName,
        headerRoleLabel: roleLabel,
        title: summary.project.name,
        subtitle: summary.project.companyName,
        body: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(projectSummaryProvider(workspaceKey));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProgressRow(
                  percent: summary.project.progressPercent,
                  inactive: !summary.project.isActive,
                ),
                const SizedBox(height: AppSpacing.md),
                _MetricsCard(summary: summary, localeName: localeName),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () {
                    if (!_usesCompanyEndpoints) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.customerOperationsHistorySoon)),
                      );
                      return;
                    }
                    final cid = workspaceKey.companyId ?? summary.project.companyId;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AggregatedOperationsHistoryScreen(
                          apiScope: TransferApiScope.company,
                          companyId: cid,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history_rounded, color: AppColors.accent),
                  label: Text(l10n.projectHistoryOperations, style: AppTextStyles.bodyStrong),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionMenu(
                  summary: summary,
                  workspaceKey: workspaceKey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final int percent;
  final bool inactive;

  const _ProgressRow({required this.percent, required this.inactive});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: LinearProgressIndicator(
                  value: percent.clamp(0, 100) / 100.0,
                  minHeight: 8,
                  backgroundColor: AppColors.surface,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.projectProgress(percent),
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        if (inactive)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l10n.projectInactive,
              style: AppTextStyles.caption.copyWith(color: AppColors.warning),
            ),
          ),
      ],
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final ProjectSummary summary;
  final String localeName;

  const _MetricsCard({required this.summary, required this.localeName});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = summary.metrics;
    final inc = formatMoneyDisplay(m.incomeTotal, localeName);
    final exp = formatMoneyDisplay(m.expenseTotal, localeName);
    final bal = formatMoneyDisplay(m.projectBalance, localeName);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.projectMetricsSectionTitle.toUpperCase(), style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          _moneyLine(context, l10n.projectIncomeMetric, inc),
          const SizedBox(height: AppSpacing.sm),
          _moneyLine(context, l10n.projectExpenseMetric, exp),
          const SizedBox(height: AppSpacing.sm),
          _moneyLine(context, l10n.projectBalanceMetric, bal),
        ],
      ),
    );
  }

  Widget _moneyLine(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary))),
        Text(value, style: AppTextStyles.bodyStrong),
      ],
    );
  }
}

class _SectionMenu extends StatelessWidget {
  final ProjectSummary summary;
  final ProjectWorkspaceKey workspaceKey;

  const _SectionMenu({
    required this.summary,
    required this.workspaceKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final v = summary.visibility;
    final companyId = workspaceKey.companyId ?? summary.project.companyId;
    final richCompany = workspaceKey.scope == ProjectWorkspaceScope.company;

    final tiles = <_MenuTile>[];

    if (richCompany && v.canViewParticipants) {
      tiles.add(
        _MenuTile(
          icon: Icons.groups_rounded,
          label: l10n.projectParticipants,
          onTap: () {
            final p = Project(
              id: summary.project.id,
              companyId: summary.project.companyId,
              name: summary.project.name,
              progressPercent: summary.project.progressPercent,
              isActive: summary.project.isActive,
              createdAt: null,
              updatedAt: null,
            );
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProjectParticipantsScreen(
                  project: p,
                  companyId: companyId,
                  metricsWorkspaceKey: v.canViewInternalMetrics ? workspaceKey : null,
                ),
              ),
            );
          },
        ),
      );
    }

    if (richCompany) {
      tiles.add(
        _MenuTile(
          icon: Icons.swap_horiz_rounded,
          label: l10n.projectOperations,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TransfersScreen(
                  companyId: companyId,
                  projectId: summary.project.id,
                  projectName: summary.project.name,
                  canCreateTransfer: v.canCreateTransfer,
                ),
              ),
            );
          },
        ),
      );
      if (v.canViewExpenseItems) {
        tiles.add(
          _MenuTile(
            icon: Icons.receipt_long_rounded,
            label: l10n.projectExpenseArticles,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProjectExpenseItemsScreen(
                    companyId: summary.project.companyId,
                    projectId: summary.project.id,
                    projectName: summary.project.name,
                    canManage: v.canManageExpenseItems,
                  ),
                ),
              );
            },
          ),
        );
      }
      if (v.canViewProjectPriceLists) {
        tiles.add(
          _MenuTile(
            icon: Icons.request_quote_outlined,
            label: l10n.projectPriceLists,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProjectPriceListsScreen(
                    companyId: summary.project.companyId,
                    projectId: summary.project.id,
                    projectName: summary.project.name,
                    canManageAttachments: v.canManageProjectPriceListAttachments,
                  ),
                ),
              );
            },
          ),
        );
      }
      tiles.add(
        _MenuTile(
          icon: Icons.description_outlined,
          label: l10n.projectDocuments,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.projectComingSoonSnippet)),
          ),
        ),
      );
      tiles.add(
        _MenuTile(
          icon: Icons.flag_outlined,
          label: l10n.projectStatus,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.projectComingSoonSnippet)),
          ),
        ),
      );
    }

    if (tiles.isEmpty) {
      return AppCard(
        child: Text(
          l10n.customerWorkspaceSubtitle,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tiles
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                onTap: t.onTap,
                child: Row(
                  children: [
                    Icon(t.icon, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(t.label, style: AppTextStyles.bodyStrong)),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MenuTile {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _MenuTile({required this.icon, required this.label, required this.onTap});
}
