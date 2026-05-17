import 'dart:math' as math;
import 'dart:ui' show ImageFilter, Locale;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../customer_workspace/presentation/money_format.dart';
import '../../operations/data/transfers_api.dart';
import '../../operations/presentation/aggregated_operations_history_screen.dart';
import '../../operations/presentation/report_detail_screen.dart';
import '../../operations/presentation/transfer_detail_screen.dart';
import '../../price_lists/presentation/company_price_lists_screen.dart';
import '../../operations/providers.dart';
import '../domain/company_dashboard_stats.dart';
import '../providers.dart';
import '../providers/company_dashboard_stats_provider.dart';

class CompanyDashboardScreen extends ConsumerStatefulWidget {
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
  ConsumerState<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();

  static void _openDocumentsMenu(BuildContext context, int companyId) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.request_quote_outlined),
              title: Text(l10n.dashboardDocumentsPriceLists),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CompanyPriceListsScreen(companyId: companyId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.hourglass_empty),
              title: Text(l10n.projectDocuments),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyDashboardScreenState extends ConsumerState<CompanyDashboardScreen> {
  String? _selectedMonthYyyyMm;

  CompanyDashboardStatsArgs get _statsArgs => (
        companyId: widget.companyId,
        selectedMonth: _selectedMonthYyyyMm,
      );

  Future<void> _refreshAll() async {
    final pendingKey = (scope: TransferApiScope.company, companyId: widget.companyId);
    ref.invalidate(companyDashboardStatsProvider(_statsArgs));
    ref.invalidate(combinedOperationsPendingCountProvider(pendingKey));
    await Future.wait<void>([
      ref.read(companyDashboardStatsProvider(_statsArgs).future),
      ref.read(combinedOperationsPendingCountProvider(pendingKey).future),
    ]);
  }

  void _toggleMonth(String monthKey) {
    setState(() {
      if (_selectedMonthYyyyMm == monthKey) {
        _selectedMonthYyyyMm = null;
      } else {
        _selectedMonthYyyyMm = monthKey;
      }
    });
  }

  Future<void> _openMetricOperations(String metric) async {
    final l10n = context.l10n;
    final locale = ref.read(localeProvider);
    final navigator = Navigator.of(context);
    final api = ref.read(companyWorkspaceApiProvider);
    try {
      final items = await api.getDashboardAnalyticsOperations(
        companyId: widget.companyId,
        metric: metric,
        month: _selectedMonthYyyyMm,
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final topInset = MediaQuery.paddingOf(ctx).top;
          final h = MediaQuery.sizeOf(ctx).height;
          return Padding(
            padding: EdgeInsets.only(top: topInset + h * 0.06),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.58,
              minChildSize: 0.32,
              maxChildSize: 0.92,
              builder: (ctx, scrollController) {
                return DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.dashboardAnalyticsOperationsTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dashboardAnalyticsMetricLabel(l10n, metric),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: items.isEmpty
                            ? ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                                children: [
                                  Text(
                                    l10n.dashboardAnalyticsOperationsEmpty,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 15,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                                itemCount: items.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (c, i) {
                                  return _AnalyticsMetricOperationTile(
                                    item: items[i],
                                    metric: metric,
                                    locale: locale,
                                    l10n: l10n,
                                    onTap: () async {
                                      final it = items[i];
                                      final kind = _dashboardAnalyticsOpKind(it);
                                      if (kind == 'aggregate' && metric == 'overpayment') {
                                        await _showOverpaymentProjectDetail(ctx, navigator, it);
                                        return;
                                      }
                                      if (kind == 'aggregate') {
                                        return;
                                      }
                                      final id = _dashboardAnalyticsOpIdNullable(it);
                                      if (id == null) {
                                        return;
                                      }
                                      final pid = _dashboardAnalyticsProjectId(it);
                                      Navigator.pop(ctx);
                                      if (kind == 'report') {
                                        navigator
                                            .push<void>(
                                          MaterialPageRoute<void>(
                                            builder: (_) => ReportDetailScreen(
                                              apiScope: TransferApiScope.company,
                                              companyId: widget.companyId,
                                              projectId: pid,
                                              reportId: id,
                                            ),
                                          ),
                                        )
                                            .then((_) => _refreshAll());
                                      } else if (kind == 'transfer') {
                                        navigator
                                            .push<void>(
                                          MaterialPageRoute<void>(
                                            builder: (_) => TransferDetailScreen(
                                              apiScope: TransferApiScope.company,
                                              companyId: widget.companyId,
                                              projectId: pid,
                                              transferId: id,
                                            ),
                                          ),
                                        )
                                            .then((_) => _refreshAll());
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transfersErrorLoad)),
      );
    }
  }

  Future<void> _showOverpaymentProjectDetail(
    BuildContext operationsSheetContext,
    NavigatorState navigator,
    Map<String, dynamic> aggregateItem,
  ) async {
    final l10n = context.l10n;
    final locale = ref.read(localeProvider);
    final pid = _dashboardAnalyticsProjectId(aggregateItem);
    await showModalBottomSheet<void>(
      context: operationsSheetContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (detailCtx) {
        final top = MediaQuery.paddingOf(detailCtx).top;
        final h = MediaQuery.sizeOf(detailCtx).height;
        return Padding(
          padding: EdgeInsets.only(top: top + h * 0.05),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.38,
            maxChildSize: 0.94,
            builder: (_, scrollController) {
              return DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                l10n.dashboardOverpaymentDetailTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(detailCtx),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _OverpaymentProjectDetailBody(
                        scrollController: scrollController,
                        companyId: widget.companyId,
                        projectId: pid,
                        month: _selectedMonthYyyyMm,
                        locale: locale,
                        operationsSheetContext: operationsSheetContext,
                        navigator: navigator,
                        onRefreshAll: _refreshAll,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = ref.watch(localeProvider);
    final statsAsync = ref.watch(companyDashboardStatsProvider(_statsArgs));

    final pendingAsync = ref.watch(
      combinedOperationsPendingCountProvider((scope: TransferApiScope.company, companyId: widget.companyId)),
    );
    final pending = pendingAsync.valueOrNull ?? 0;
    final historyBadge = pending > 0 ? '$pending' : null;

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
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _AnalyticsCard(
            accent: CompanyDashboardScreen._accent,
            barNumberColor: CompanyDashboardScreen._barLabelInside,
            l10n: l10n,
            locale: locale,
            stats: statsAsync.valueOrNull,
            loading: statsAsync.isLoading && statsAsync.valueOrNull == null,
            statsError: statsAsync.hasError,
            selectedMonthKey: _selectedMonthYyyyMm,
            onSelectMonthKey: _toggleMonth,
            onTapIncome: () => _openMetricOperations('income'),
            onTapDebt: () => _openMetricOperations('debt'),
            onTapOverpayment: () => _openMetricOperations('overpayment'),
            onTapActiveProjectsHeader: widget.onOpenProjects,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.work_outline,
                  title: l10n.dashboardProjectsTile,
                  value: projValue,
                  onTap: widget.onOpenProjects,
                  onAdd: widget.onQuickCreateProject,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.group_outlined,
                  title: l10n.dashboardCounterpartiesTile,
                  value: cpValue,
                  onTap: widget.onOpenCounterparties,
                  onAdd: widget.onQuickCreateCounterparty,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WideNavTileGlass(
            icon: Icons.folder_outlined,
            title: l10n.dashboardDocuments,
            onTap: () => CompanyDashboardScreen._openDocumentsMenu(context, widget.companyId),
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
                  builder: (_) => AggregatedOperationsHistoryScreen(
                    apiScope: TransferApiScope.company,
                    companyId: widget.companyId,
                  ),
                ),
              )
                  .then((_) => _refreshAll());
            },
          ),
        ],
      ),
    );
  }
}

class _OverpaymentProjectDetailBody extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final int companyId;
  final int projectId;
  final String? month;
  final Locale locale;
  final BuildContext operationsSheetContext;
  final NavigatorState navigator;
  final Future<void> Function() onRefreshAll;

  const _OverpaymentProjectDetailBody({
    required this.scrollController,
    required this.companyId,
    required this.projectId,
    required this.locale,
    required this.operationsSheetContext,
    required this.navigator,
    required this.onRefreshAll,
    this.month,
  });

  @override
  ConsumerState<_OverpaymentProjectDetailBody> createState() => _OverpaymentProjectDetailBodyState();
}

class _OverpaymentProjectDetailBodyState extends ConsumerState<_OverpaymentProjectDetailBody> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.projectId <= 0) {
      setState(() {
        _loading = false;
        _error = context.l10n.dashboardOverpaymentDetailLoadError;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(companyWorkspaceApiProvider);
      final data = await api.getOverpaymentProjectDetail(
        companyId: widget.companyId,
        projectId: widget.projectId,
        month: widget.month,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.dashboardOverpaymentDetailLoadError;
      });
    }
  }

  void _closeSheetsAndOpenReport(int reportId, int projectId) {
    Navigator.pop(context);
    Navigator.pop(widget.operationsSheetContext);
    widget.navigator
        .push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReportDetailScreen(
          apiScope: TransferApiScope.company,
          companyId: widget.companyId,
          projectId: projectId,
          reportId: reportId,
        ),
      ),
    )
        .then((_) => widget.onRefreshAll());
  }

  void _closeSheetsAndOpenTransfer(int transferId, int projectId) {
    Navigator.pop(context);
    Navigator.pop(widget.operationsSheetContext);
    widget.navigator
        .push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TransferDetailScreen(
          apiScope: TransferApiScope.company,
          companyId: widget.companyId,
          projectId: projectId,
          transferId: transferId,
        ),
      ),
    )
        .then((_) => widget.onRefreshAll());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeName = widget.locale.toString();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.35),
          ),
        ),
      );
    }

    final data = _data;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final projectName = (data['project_name'] ?? '').toString().trim();
    final name = projectName.isEmpty ? l10n.dashboardAnalyticsProjectFallback : projectName;
    final received = formatMoneyDisplay((data['received_amount'] ?? '').toString(), localeName);
    final earned = formatMoneyDisplay((data['earned_amount'] ?? '').toString(), localeName);
    final remainder = formatMoneyDisplay((data['overpayment_amount'] ?? '').toString(), localeName);
    final transfers = (data['transfers'] as List?)?.map((e) => (e as Map).cast<String, dynamic>()).toList() ?? [];
    final reports = (data['reports'] as List?)?.map((e) => (e as Map).cast<String, dynamic>()).toList() ?? [];
    final projectId = _dashboardAnalyticsProjectId(data);

    Widget summaryRow(String label, String value, {bool accent = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accent ? AppColors.accent : AppColors.textPrimary,
                fontWeight: accent ? FontWeight.w700 : FontWeight.w600,
                fontSize: 15,
                height: 1.25,
              ),
            ),
          ],
        ),
      );
    }

    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    Widget opTile(Map<String, dynamic> row, {required bool isReport}) {
      final kind = _dashboardAnalyticsOpKind(row);
      final typeLabel = kind == 'report' ? l10n.operationReport : l10n.operationTransfer;
      final code = _dashboardAnalyticsDisplayCode(row);
      final datePart = _dashboardAnalyticsFormatOpDate(row['operation_date'] as String?, widget.locale);
      final headline = code.isEmpty
          ? (datePart.isEmpty ? typeLabel : '$typeLabel · $datePart')
          : (datePart.isEmpty ? '$typeLabel $code' : '$typeLabel $code · $datePart');
      final amtRaw = (row['metric_amount'] ?? row['earned_amount'] ?? '').toString();
      final amt = formatMoneyDisplay(amtRaw, localeName);
      final id = _dashboardAnalyticsOpIdNullable(row);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: id == null
              ? null
              : () {
                  if (isReport) {
                    _closeSheetsAndOpenReport(id, projectId);
                  } else {
                    _closeSheetsAndOpenTransfer(id, projectId);
                  }
                },
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFF121820),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amt,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 16),
        summaryRow(l10n.dashboardOverpaymentDetailReceivedLabel, received),
        summaryRow(l10n.dashboardOverpaymentDetailEarnedReportsLabel, earned),
        summaryRow(l10n.dashboardOverpaymentDetailRemainderLabel, remainder, accent: true),
        sectionTitle(l10n.dashboardOverpaymentDetailTransfersSection),
        if (transfers.isEmpty)
          Text(
            l10n.dashboardAnalyticsOperationsEmpty,
            style: const TextStyle(color: AppColors.textHint, fontSize: 14),
          )
        else
          ...transfers.map((row) => Padding(padding: const EdgeInsets.only(bottom: 8), child: opTile(row, isReport: false))),
        sectionTitle(l10n.dashboardOverpaymentDetailReportsSection),
        if (reports.isEmpty)
          Text(
            l10n.dashboardAnalyticsOperationsEmpty,
            style: const TextStyle(color: AppColors.textHint, fontSize: 14),
          )
        else
          ...reports.map((row) => Padding(padding: const EdgeInsets.only(bottom: 8), child: opTile(row, isReport: true))),
      ],
    );
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
  final Locale locale;
  final CompanyDashboardStats? stats;
  final bool loading;
  final bool statsError;
  final String? selectedMonthKey;
  final void Function(String monthKey) onSelectMonthKey;
  final VoidCallback onTapIncome;
  final VoidCallback onTapDebt;
  final VoidCallback onTapOverpayment;
  final VoidCallback onTapActiveProjectsHeader;

  const _AnalyticsCard({
    required this.accent,
    required this.barNumberColor,
    required this.l10n,
    required this.locale,
    required this.stats,
    required this.loading,
    required this.statsError,
    required this.selectedMonthKey,
    required this.onSelectMonthKey,
    required this.onTapIncome,
    required this.onTapDebt,
    required this.onTapOverpayment,
    required this.onTapActiveProjectsHeader,
  });

  String _analyticsTitle() {
    if (selectedMonthKey == null || selectedMonthKey!.length < 7) {
      return l10n.dashboardQuarterAnalytics;
    }
    final parts = selectedMonthKey!.split('-');
    if (parts.length < 2) return l10n.dashboardQuarterAnalytics;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (y == null || m == null) return l10n.dashboardQuarterAnalytics;
    final d = DateTime(y, m);
    final monthName = DateFormat.MMMM(locale.toLanguageTag()).format(d);
    return l10n.dashboardMonthAnalytics(monthName);
  }

  String _money(String raw) {
    final v = formatMoneyDisplay(raw, locale.toLanguageTag());
    return '$v ₽';
  }

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final income = s != null ? _money(s.incomeRaw) : (loading ? '…' : _money('0.00'));
    final debt = s != null ? _money(s.debtRaw) : (loading ? '…' : _money('0.00'));
    final over = s != null ? _money(s.overpaymentRaw) : (loading ? '…' : _money('0.00'));

    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _analyticsTitle(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                    InkWell(
                      onTap: statsError ? null : onTapIncome,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                        child: Text(
                          statsError ? '—' : income,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.dashboardDebt,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: statsError ? null : onTapDebt,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                        child: Text(
                          statsError ? '—' : debt,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.dashboardOverpayment,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: statsError ? null : onTapOverpayment,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                        child: Text(
                          statsError ? '—' : over,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
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
                    InkWell(
                      onTap: onTapActiveProjectsHeader,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          l10n.dashboardActiveProjects,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _QuarterProjectBars(
                      accent: accent,
                      numberColor: barNumberColor,
                      bars: stats?.quarterBars,
                      loading: loading,
                      statsError: statsError,
                      selectedMonthKey: selectedMonthKey,
                      onSelectMonthKey: onSelectMonthKey,
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
  final String? selectedMonthKey;
  final void Function(String monthKey) onSelectMonthKey;

  static const double _chartHeight = 118;
  static const double _maxBarPx = 86;
  static const double _minBarPx = 6;

  const _QuarterProjectBars({
    required this.accent,
    required this.numberColor,
    required this.bars,
    required this.loading,
    required this.statsError,
    required this.selectedMonthKey,
    required this.onSelectMonthKey,
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
                monthKey: list[i].monthKey,
                isSelected: selectedMonthKey == list[i].monthKey,
                onTap: () => onSelectMonthKey(list[i].monthKey),
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
  final String monthKey;
  final bool isSelected;
  final VoidCallback onTap;

  const _BarColumn({
    required this.accent,
    required this.numberColor,
    required this.label,
    required this.count,
    required this.barHeight,
    required this.maxBarPx,
    required this.monthKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? Colors.black.withValues(alpha: 0.22) : Colors.transparent,
        ),
        child: Column(
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
                    color: accent.withValues(alpha: isSelected ? 0.75 : 1.0),
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
        ),
      ),
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

String _dashboardAnalyticsMetricLabel(AppLocalizations l10n, String metric) {
  switch (metric) {
    case 'debt':
      return l10n.dashboardAnalyticsMetricDebt;
    case 'overpayment':
      return l10n.dashboardAnalyticsMetricOverpayment;
    case 'income':
    default:
      return l10n.dashboardAnalyticsMetricIncome;
  }
}

String _dashboardAnalyticsOpKind(Map<String, dynamic> it) =>
    (it['operation_kind'] ?? it['type'] ?? '').toString();

int? _dashboardAnalyticsOpIdNullable(Map<String, dynamic> it) {
  final v = it['operation_id'] ?? it['id'];
  if (v == null) {
    return null;
  }
  if (v is num) {
    final i = v.toInt();
    return i <= 0 ? null : i;
  }
  final p = int.tryParse('$v');
  if (p == null || p <= 0) {
    return null;
  }
  return p;
}

int _dashboardAnalyticsProjectId(Map<String, dynamic> it) {
  final v = it['project_id'];
  if (v is num) {
    return v.toInt();
  }
  return int.tryParse('$v') ?? 0;
}

String _dashboardAnalyticsDisplayCode(Map<String, dynamic> it) {
  final kind = _dashboardAnalyticsOpKind(it);
  if (kind == 'aggregate') {
    return '';
  }
  final raw = it['operation_number'];
  if (raw is String) {
    final t = raw.trim();
    if (t.isNotEmpty) {
      return t;
    }
  }
  final sub = it['subtitle'];
  if (sub is String) {
    final t = sub.trim();
    if (t.isNotEmpty) {
      return t;
    }
  }
  final id = _dashboardAnalyticsOpIdNullable(it);
  if (kind == 'transfer') {
    return id != null ? 'TRF-$id' : '';
  }
  return id != null ? 'REP-$id' : '';
}

String _dashboardAnalyticsFormatOpDate(String? iso, Locale locale) {
  if (iso == null || iso.isEmpty) {
    return '';
  }
  final d = DateTime.tryParse(iso);
  if (d == null) {
    return iso;
  }
  final local = DateTime(d.year, d.month, d.day);
  return DateFormat.yMMMd(locale.toString()).format(local);
}

const TextStyle _metricSecondaryAmountStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 13,
  height: 1.25,
);

List<Widget> _metricAmountLines(
  AppLocalizations l10n,
  String metric,
  String kind,
  Map<String, dynamic> item,
  String localeName,
) {
  String fmt(String raw) => formatMoneyDisplay(raw, localeName);
  final metricRaw = (item['metric_amount'] ?? item['amount'] ?? '').toString();

  if (metric == 'income') {
    if (kind == 'report') {
      return [
        Text(
          l10n.dashboardAnalyticsIncomeFromReport(fmt(metricRaw)),
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            height: 1.25,
          ),
        ),
      ];
    }
    return [
      Text(
        l10n.dashboardAnalyticsReceivedAmount(fmt(metricRaw)),
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          height: 1.25,
        ),
      ),
    ];
  }

  if (metric == 'debt') {
    final a = (item['earned_amount'] ?? item['accrued_amount'] ?? '').toString();
    final r = (item['received_amount'] ?? '').toString();
    final d = (item['debt_amount'] ?? metricRaw).toString();
    return [
      Text(l10n.dashboardAnalyticsAccruedAmount(fmt(a)), style: _metricSecondaryAmountStyle),
      const SizedBox(height: 4),
      Text(l10n.dashboardAnalyticsReceivedAmount(fmt(r)), style: _metricSecondaryAmountStyle),
      const SizedBox(height: 6),
      Text(
        l10n.dashboardAnalyticsDebtAmount(fmt(d)),
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          height: 1.25,
        ),
      ),
    ];
  }

  if (metric == 'overpayment') {
    final a = (item['earned_amount'] ?? item['accrued_amount'] ?? '').toString();
    final r = (item['received_amount'] ?? '').toString();
    final o = (item['overpayment_amount'] ?? metricRaw).toString();
    return [
      Text(l10n.dashboardAnalyticsAccruedAmount(fmt(a)), style: _metricSecondaryAmountStyle),
      const SizedBox(height: 4),
      Text(l10n.dashboardAnalyticsReceivedAmount(fmt(r)), style: _metricSecondaryAmountStyle),
      const SizedBox(height: 6),
      Text(
        l10n.dashboardAnalyticsOverpaymentAmount(fmt(o)),
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          height: 1.25,
        ),
      ),
    ];
  }

  return [
    Text(
      fmt(metricRaw),
      style: const TextStyle(
        color: AppColors.accent,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    ),
  ];
}

class _AnalyticsMetricOperationTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String metric;
  final Locale locale;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _AnalyticsMetricOperationTile({
    required this.item,
    required this.metric,
    required this.locale,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localeName = locale.toString();
    final kind = _dashboardAnalyticsOpKind(item);
    final projectRaw = (item['project_name'] ?? '').toString().trim();
    final project = projectRaw.isEmpty ? l10n.dashboardAnalyticsProjectFallback : projectRaw;
    final status = (item['status'] ?? '').toString();

    String headline;
    if (kind == 'aggregate') {
      headline = item['title'] == 'aggregate_project_overpayment'
          ? l10n.dashboardAnalyticsAggregateOverpaymentTitle
          : (item['title'] ?? '').toString();
    } else {
      final typeLabel = kind == 'report' ? l10n.operationReport : l10n.operationTransfer;
      final code = _dashboardAnalyticsDisplayCode(item);
      final datePart = _dashboardAnalyticsFormatOpDate(item['operation_date'] as String?, locale);
      if (code.isEmpty) {
        headline = datePart.isEmpty ? typeLabel : '$typeLabel · $datePart';
      } else {
        headline = datePart.isEmpty ? '$typeLabel $code' : '$typeLabel $code · $datePart';
      }
    }

    final fifoHint = item['fifo_analytic_closure'] == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF121820),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                ..._metricAmountLines(l10n, metric, kind, item, localeName),
                if (fifoHint) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.dashboardAnalyticsAnalyticClosureNote,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      height: 1.25,
                    ),
                  ),
                ],
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.dashboardAnalyticsOperationStatus(status),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
