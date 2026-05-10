import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loader.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers.dart';
import '../../customer_workspace/presentation/money_format.dart';
import '../providers.dart';
import 'monthly_income_chart.dart';
import 'performer_company_vms.dart';
import 'personal_operations_tab.dart';

class PersonalWorkspaceShell extends ConsumerStatefulWidget {
  const PersonalWorkspaceShell({super.key});

  @override
  ConsumerState<PersonalWorkspaceShell> createState() => _PersonalWorkspaceShellState();
}

class _PersonalWorkspaceShellState extends ConsumerState<PersonalWorkspaceShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            const _PerformerHomeBody(),
            const PersonalOperationsTab(),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3l, vertical: AppSpacing.xl),
                child: Text(
                  l10n.notificationsComingSoon,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: NavigationBar(
          height: 64,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.accent.withValues(alpha: 0.18),
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.customerHomeTitle,
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
              label: l10n.navOperations,
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_outlined),
              selectedIcon: const Icon(Icons.notifications_active_outlined),
              label: l10n.navNotifications,
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformerHomeBody extends ConsumerWidget {
  const _PerformerHomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final async = ref.watch(performerWorkspaceDataProvider);

    Future<void> reload() async {
      ref.invalidate(performerWorkspaceDataProvider);
      await ref.read(performerWorkspaceDataProvider.future);
    }

    return async.when(
      data: (data) {
        final vms = buildPerformerCompanyVms(data.companies, data.projects, l10n, localeName);
        if (vms.isEmpty) {
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _PerformerTopBar(onWorkspaces: () => context.go('/workspaces'))),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.work_outline_rounded,
                    title: l10n.personalWorkspaceEmpty,
                    description: l10n.personalWorkspacePlaceholder,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: reload,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _PerformerTopBar(onWorkspaces: () => context.go('/workspaces'))),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _IncomeHeaderCard(
                    totalFormatted: formatMoneyDisplay(data.incomeTotalForPeriod, localeName),
                    chart: MonthlyIncomeChart(months: data.incomeMonths, localeName: localeName),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                  child: Row(
                    children: [
                      Text(l10n.personalTop5Title, style: AppTextStyles.screenTitle),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('/personal/companies'),
                        child: Text(
                          l10n.personalShowAllLink,
                          style: AppTextStyles.bodyStrong.copyWith(color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                sliver: SliverList.separated(
                  itemCount: vms.length > 5 ? 5 : vms.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final m = vms[i];
                    return _PerformerCompanyTile(model: m);
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: AppLoader()),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3l),
          child: Text(
            l10n.personalWorkspaceLoadError,
            style: AppTextStyles.body.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _PerformerTopBar extends ConsumerWidget {
  final VoidCallback onWorkspaces;

  const _PerformerTopBar({required this.onWorkspaces});

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

class _IncomeHeaderCard extends StatelessWidget {
  final String totalFormatted;
  final Widget chart;

  const _IncomeHeaderCard({
    required this.totalFormatted,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppRadii.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.personalIncomeTitle, style: AppTextStyles.cardTitle),
              ),
              Icon(Icons.settings_outlined, color: AppColors.textHint, size: 22),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            totalFormatted,
            style: AppTextStyles.screenTitle.copyWith(
              color: AppColors.accent,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.personalIncomePeriodSubtitle,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          chart,
        ],
      ),
    );
  }
}

class _PerformerCompanyTile extends StatelessWidget {
  final PerformerCompanyVm model;

  const _PerformerCompanyTile({
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = model.company;
    final letter = c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';
    final hue = (c.name.hashCode & 0x7FFFFFFF) % 360;
    final dot = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.48).toColor();

    return AppCard(
      onTap: () => context.go('/company/${c.id}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppRadii.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: dot,
                foregroundColor: Colors.white,
                child: Text(letter, style: AppTextStyles.bodyStrong),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  c.name,
                  style: AppTextStyles.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text(
                  '${c.projectsCount}',
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _kv(l10n.personalRoleInCompany, model.roleLabel),
                const Divider(height: AppSpacing.lg, color: AppColors.border),
                _kv(l10n.customerBalancePersonal, model.balance),
                const Divider(height: AppSpacing.lg, color: AppColors.border),
                _kv(l10n.walletReceived, model.received),
                const Divider(height: AppSpacing.lg, color: AppColors.border),
                _kv(l10n.walletEarned, model.earned),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Expanded(child: Text(k, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary))),
        Text(v, style: AppTextStyles.bodyStrong),
      ],
    );
  }
}
