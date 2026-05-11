import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../operations/data/transfers_api.dart';
import '../../operations/presentation/aggregated_transfers_history_screen.dart';
import '../../operations/providers.dart';
import '../domain/company_dashboard_stats.dart';
import '../providers/company_dashboard_stats_provider.dart';

class CompanyDashboardScreen extends ConsumerWidget {
  final int companyId;
  final VoidCallback onOpenProjects;
  final VoidCallback onOpenCounterparties;
  final VoidCallback onQuickCreateProject;
  final VoidCallback onQuickCreateCounterparty;

  const CompanyDashboardScreen({
    super.key,
    required this.companyId,
    required this.onOpenProjects,
    required this.onOpenCounterparties,
    required this.onQuickCreateProject,
    required this.onQuickCreateCounterparty,
  });

  static const _accent = Color(0xFF00D6C9);
  static const _barLabelInside = Color(0xFF0A1E1C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statsAsync = ref.watch(companyDashboardStatsProvider(companyId));

    final pendingAsync = ref.watch(
      combinedOperationsPendingCountProvider((scope: TransferApiScope.company, companyId: companyId)),
    );
    final pending = pendingAsync.valueOrNull ?? 0;
    final historyBadge = pending > 0 ? '$pending' : null;

    final pendingKey = (scope: TransferApiScope.company, companyId: companyId);

    Future<void> refreshAll() async {
      ref.invalidate(companyDashboardStatsProvider(companyId));
      ref.invalidate(combinedOperationsPendingCountProvider(pendingKey));
      await Future.wait<void>([
        ref.read(companyDashboardStatsProvider(companyId).future),
        ref.read(combinedOperationsPendingCountProvider(pendingKey).future),
      ]);
    }

    final cpValue = statsAsync.when(
      data: (s) => '${s.counterpartiesTotal}',
      loading: () => '…',
      error: (_, _) => '—',
    );
    final projValue = statsAsync.when(
      data: (s) => '${s.activeProjectsTotal}',
      loading: () => '…',
      error: (_, _) => '—',
    );

    return RefreshIndicator(
      color: CompanyDashboardScreen._accent,
      onRefresh: refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _AnalyticsCard(
            accent: _accent,
            barNumberColor: _barLabelInside,
            l10n: l10n,
            stats: statsAsync.valueOrNull,
            loading: statsAsync.isLoading && statsAsync.valueOrNull == null,
            statsError: statsAsync.hasError,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.work_outline,
                  title: l10n.dashboardProjectsTile,
                  value: projValue,
                  onTap: onOpenProjects,
                  onAdd: onQuickCreateProject,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.group_outlined,
                  title: l10n.dashboardCounterpartiesTile,
                  value: cpValue,
                  onTap: onOpenCounterparties,
                  onAdd: onQuickCreateCounterparty,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WideNavTileGlass(
            icon: Icons.folder_outlined,
            title: l10n.dashboardDocuments,
            onTap: () => _toast(context, l10n.dashboardDocumentsSoon),
          ),
          const SizedBox(height: 12),
          _WideNavTileGlass(
            icon: Icons.history,
            title: l10n.dashboardHistory,
            subtitle: l10n.dashboardAwaitingConfirmation,
            badgeText: historyBadge,
            onTap: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute<void>(
                  builder: (_) => AggregatedTransfersHistoryScreen(
                    apiScope: TransferApiScope.company,
                    companyId: companyId,
                  ),
                ),
              )
                  .then((_) => refreshAll());
            },
          ),
        ],
      ),
    );
  }

  static void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.11),
                const Color(0xFF00D6C9).withValues(alpha: 0.06),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final Color accent;
  final Color barNumberColor;
  final AppLocalizations l10n;
  final CompanyDashboardStats? stats;
  final bool loading;
  final bool statsError;

  const _AnalyticsCard({
    required this.accent,
    required this.barNumberColor,
    required this.l10n,
    required this.stats,
    required this.loading,
    required this.statsError,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.dashboardQuarterAnalytics,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('TODO: analytics settings'))),
                icon: const Icon(Icons.settings, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardIncome,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '—',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.dashboardDebt,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '—',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.dashboardOverpayment,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '—',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.dashboardMetricsPending,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardActiveProjects,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    const SizedBox(height: 8),
                    _QuarterProjectBars(
                      accent: accent,
                      numberColor: barNumberColor,
                      bars: stats?.quarterBars,
                      loading: loading,
                      statsError: statsError,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Столбики выровнены по нижнему краю (подписи месяцев на одной линии).
class _QuarterProjectBars extends StatelessWidget {
  final Color accent;
  final Color numberColor;
  final List<QuarterMonthBarData>? bars;
  final bool loading;
  final bool statsError;

  static const double _chartHeight = 118;
  static const double _maxBarPx = 86;
  static const double _minBarPx = 6;

  const _QuarterProjectBars({
    required this.accent,
    required this.numberColor,
    required this.bars,
    required this.loading,
    required this.statsError,
  });

  @override
  Widget build(BuildContext context) {
    if (statsError && bars == null) {
      return SizedBox(
        height: _chartHeight,
        child: Center(
          child: Text(
            '—',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 20),
          ),
        ),
      );
    }
    if (loading || bars == null || bars!.isEmpty) {
      return SizedBox(
        height: _chartHeight,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent.withValues(alpha: 0.85),
            ),
          ),
        ),
      );
    }

    final list = bars!;
    final maxCount = list.map((e) => e.activeProjectsCount).reduce(math.max);
    double barHeight(int count) {
      if (maxCount == 0) return _minBarPx;
      final r = count / maxCount;
      return math.max(_minBarPx, r * _maxBarPx);
    }

    return SizedBox(
      height: _chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _BarColumn(
                accent: accent,
                numberColor: numberColor,
                label: list[i].label,
                count: list[i].activeProjectsCount,
                barHeight: barHeight(list[i].activeProjectsCount),
                maxBarPx: _maxBarPx,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final Color accent;
  final Color numberColor;
  final String label;
  final int count;
  final double barHeight;
  final double maxBarPx;

  const _BarColumn({
    required this.accent,
    required this.numberColor,
    required this.label,
    required this.count,
    required this.barHeight,
    required this.maxBarPx,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 40,
              height: barHeight.clamp(0, maxBarPx + 8),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: numberColor,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _MiniStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: _GlassCard(
        padding: const EdgeInsets.all(16),
        radius: 28,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const Spacer(),
                InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: CompanyDashboardScreen._accent.withValues(alpha: 0.8)),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, color: CompanyDashboardScreen._accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _WideNavTileGlass extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badgeText;
  final VoidCallback onTap;

  const _WideNavTileGlass({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: _GlassCard(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (badgeText != null)
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CompanyDashboardScreen._accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: CompanyDashboardScreen._accent.withValues(alpha: 0.25)),
                ),
                child: Text(
                  badgeText!,
                  style:
                      const TextStyle(color: CompanyDashboardScreen._accent, fontWeight: FontWeight.w700),
                ),
              )
            else
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.85)),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: subtitle == null
                  ? Text(title, style: const TextStyle(fontWeight: FontWeight.w600))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: CompanyDashboardScreen._accent,
                          ),
                        ),
                      ],
                    ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.65)),
          ],
        ),
      ),
    );
  }
}
