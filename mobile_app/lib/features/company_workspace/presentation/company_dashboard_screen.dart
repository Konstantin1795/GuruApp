import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../operations/data/transfers_api.dart';
import '../../operations/presentation/aggregated_transfers_history_screen.dart';
import '../../operations/providers.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(
      transferPendingActionCountProvider((scope: TransferApiScope.company, companyId: companyId)),
    );
    final pending = pendingAsync.valueOrNull ?? 0;
    final historyBadge = pending > 0 ? '$pending' : null;

    final pendingKey = (scope: TransferApiScope.company, companyId: companyId);

    Future<void> refreshPendingCount() async {
      ref.invalidate(transferPendingActionCountProvider(pendingKey));
      await ref.read(transferPendingActionCountProvider(pendingKey).future);
    }

    return RefreshIndicator(
      color: CompanyDashboardScreen._accent,
      onRefresh: refreshPendingCount,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
        _AnalyticsCard(),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                icon: Icons.work_outline,
                title: 'Проекты',
                value: '5',
                onTap: onOpenProjects,
                onAdd: onQuickCreateProject,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.group_outlined,
                title: 'Контрагенты',
                value: '5',
                onTap: onOpenCounterparties,
                onAdd: onQuickCreateCounterparty,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _WideNavTileGlass(
          icon: Icons.folder_outlined,
          title: 'Документы',
          onTap: () => _toast(context, 'TODO: документы'),
        ),
        const SizedBox(height: 12),
        _WideNavTileGlass(
          icon: Icons.history,
          title: 'История операций',
          subtitle: 'Ожидают подтверждения',
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
                .then((_) => refreshPendingCount());
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
  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Аналитика за квартал',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                    Text('Доход', style: TextStyle(color: Colors.white.withValues(alpha: 0.65))),
                    const SizedBox(height: 4),
                    const Text(
                      '350 000,00',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CompanyDashboardScreen._accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Задолженность',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.65))),
                    const SizedBox(height: 4),
                    const Text('57 456,00',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text('Переплата',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.65))),
                    const SizedBox(height: 4),
                    const Text('745,00',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Активные проекты',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.65))),
                    const SizedBox(height: 8),
                    _Bars(),
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

class _Bars extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget bar(double h, {required String label, required String value, bool tiny = false}) {
      return Column(
        children: [
          Container(
            width: 44,
            height: h,
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(
              color: CompanyDashboardScreen._accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        bar(92, label: 'фев', value: '7'),
                      bar(24, label: 'мар', value: ''),
        bar(84, label: 'апр', value: '6'),
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

