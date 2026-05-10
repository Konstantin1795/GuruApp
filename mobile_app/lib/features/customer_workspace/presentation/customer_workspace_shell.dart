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
import '../../../features/auth/presentation/login_screen.dart';
import '../../auth/providers.dart';
import '../../operations/data/transfers_api.dart';
import '../../operations/presentation/aggregated_transfers_history_screen.dart';
import '../../operations/providers.dart';
import '../domain/personal_workspace_project_row.dart';
import '../providers.dart';
import 'money_format.dart';

class CustomerWorkspaceShell extends ConsumerStatefulWidget {
  const CustomerWorkspaceShell({super.key});

  @override
  ConsumerState<CustomerWorkspaceShell> createState() => _CustomerWorkspaceShellState();
}

class _CustomerWorkspaceShellState extends ConsumerState<CustomerWorkspaceShell> {
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
            const _CustomerHomeBody(),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x3l,
                  vertical: AppSpacing.xl,
                ),
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

class _CustomerHomeBody extends ConsumerWidget {
  const _CustomerHomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final async = ref.watch(customerWorkspaceDataProvider);

    final pendingKey = (scope: TransferApiScope.personal, companyId: 0);

    Future<void> reload() async {
      ref.invalidate(customerWorkspaceDataProvider);
      ref.invalidate(transferPendingActionCountProvider(pendingKey));
      await Future.wait([
        ref.read(customerWorkspaceDataProvider.future),
        ref.read(transferPendingActionCountProvider(pendingKey).future),
      ]);
    }

    return async.when(
      data: (data) {
        if (data.projects.isEmpty) {
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _HomeTopBar(onWorkspaces: () => context.go('/workspaces'))),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.construction_rounded,
                    title: l10n.customerNoData,
                    description: l10n.customerWorkspaceSubtitle,
                  ),
                ),
              ],
            ),
          );
        }
        final pendingAsync = ref.watch(
          transferPendingActionCountProvider((scope: TransferApiScope.personal, companyId: 0)),
        );
        final pendingTransfers = pendingAsync.valueOrNull ?? 0;

        return _HomeScrollContent(
          projects: data.projects,
          localeName: localeName,
          onWorkspaces: () => context.go('/workspaces'),
          onRefresh: reload,
          pendingTransferActions: pendingTransfers,
          onOperationsHistoryClosed: () => ref.invalidate(
                transferPendingActionCountProvider((scope: TransferApiScope.personal, companyId: 0)),
              ),
        );
      },
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: const AppLoader(),
        ),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3l),
          child: Text(
            l10n.customerErrorLoad,
            style: AppTextStyles.body.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _HomeTopBar extends ConsumerWidget {
  final VoidCallback onWorkspaces;

  const _HomeTopBar({required this.onWorkspaces});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
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
            icon: const Icon(Icons.apps_rounded),
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
          Text(
            l10n.roleCustomer,
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          const LocaleSwitchButton(),
        ],
      ),
    );
  }
}

class _HomeScrollContent extends StatefulWidget {
  final List<PersonalWorkspaceProjectRow> projects;
  final String localeName;
  final VoidCallback onWorkspaces;
  final Future<void> Function() onRefresh;
  final int pendingTransferActions;
  final VoidCallback onOperationsHistoryClosed;

  const _HomeScrollContent({
    required this.projects,
    required this.localeName,
    required this.onWorkspaces,
    required this.onRefresh,
    required this.pendingTransferActions,
    required this.onOperationsHistoryClosed,
  });

  @override
  State<_HomeScrollContent> createState() => _HomeScrollContentState();
}

class _HomeScrollContentState extends State<_HomeScrollContent> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final projects = widget.projects;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _HomeTopBar(onWorkspaces: widget.onWorkspaces)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                height: 268,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: projects.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _FeaturedProjectCard(
                    row: projects[i],
                    localeName: widget.localeName,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _CarouselDots(count: projects.length, active: _page),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              child: Column(
                children: [
                  _MenuButton(
                    icon: Icons.hub_outlined,
                    title: l10n.customerAllProjects,
                    trailing: Text(
                      '${projects.length}',
                      style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textSecondary),
                    ),
                    onTap: () => context.push('/customer/companies'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _MenuButton(
                    icon: Icons.description_outlined,
                    title: l10n.customerDocuments,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.customerDocumentsSoon)),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _MenuButton(
                    icon: Icons.history_outlined,
                    title: l10n.dashboardHistory,
                    subtitleWidget: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.customerAwaitingBadge,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    trailing: widget.pendingTransferActions > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${widget.pendingTransferActions}',
                              style: AppTextStyles.bodyStrong.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AggregatedTransfersHistoryScreen(
                                apiScope: TransferApiScope.personal,
                                companyId: 0,
                              ),
                            ),
                          )
                          .then((_) => widget.onOperationsHistoryClosed());
                    },
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  final int count;
  final int active;

  const _CarouselDots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final on = i == active;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: on ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: on ? AppColors.accent : AppColors.textDisabled,
            ),
          );
        }),
      ),
    );
  }
}

class _FeaturedProjectCard extends StatelessWidget {
  final PersonalWorkspaceProjectRow row;
  final String localeName;

  const _FeaturedProjectCard({
    required this.row,
    required this.localeName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final w = row.wallet;
    final received = formatMoneyDisplay(w.personalReceived, localeName);
    final spent = formatMoneyDisplay(w.accountableSpent, localeName);
    final balance = formatMoneyDisplay(w.personalBalance, localeName);

    return SizedBox(
      height: 252,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        radius: AppRadii.xxl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    row.projectName,
                    style: AppTextStyles.cardTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.settings_outlined, color: AppColors.textHint, size: 22),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              row.companyName,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _moneyLine(l10n.customerReceived, received),
                        const SizedBox(height: 6),
                        _moneyLine(l10n.customerSpentAccumulated, spent),
                        const SizedBox(height: 6),
                        _moneyLine(l10n.customerBalancePersonal, balance),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _ProgressRing(percent: row.progressPercent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyLine(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final int percent;

  const _ProgressRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = (percent.clamp(0, 100)) / 100.0;
    return SizedBox(
      width: 104,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.customerProgress,
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: p,
                    strokeWidth: 6,
                    backgroundColor: AppColors.border,
                    color: AppColors.accent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  l10n.customerProgressPercent(percent),
                  style: AppTextStyles.bodyStrong.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Widget? subtitleWidget;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.title,
    this.trailing,
    this.subtitleWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      radius: AppRadii.xl,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.accentBorder),
            ),
            child: Icon(icon, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyStrong),
                if (subtitleWidget != null) subtitleWidget!,
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
