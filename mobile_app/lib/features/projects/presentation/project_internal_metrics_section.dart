import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loader.dart';
import '../../customer_workspace/presentation/money_format.dart';
import '../domain/project_workspace_scope.dart';
import '../providers.dart';

/// Блок «Данные по проекту» (ТЗ-07 §14) — только при доступе к internal-metrics API.
class ProjectInternalMetricsSection extends ConsumerWidget {
  final ProjectWorkspaceKey workspaceKey;

  const ProjectInternalMetricsSection({super.key, required this.workspaceKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectInternalMetricsProvider(workspaceKey));
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: Center(child: AppLoader()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (m) {
        if (m == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.projectInternalDataTitle.toUpperCase(), style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.md),
                _line(l10n.participantsAccountableBalance, formatMoneyDisplay(m.participantsAccountableBalance, locale)),
                const SizedBox(height: AppSpacing.sm),
                _line(l10n.projectDebtToCounterparties, formatMoneyDisplay(m.projectDebtToCounterparties, locale)),
                const SizedBox(height: AppSpacing.sm),
                _line(l10n.projectOverpaymentOrMissingReports, formatMoneyDisplay(m.overpaymentOrMissingReports, locale)),
                const SizedBox(height: AppSpacing.sm),
                _line(l10n.projectBalanceMetric, formatMoneyDisplay(m.projectBalance, locale)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _line(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ),
        Text(value, style: AppTextStyles.bodyStrong),
      ],
    );
  }
}
