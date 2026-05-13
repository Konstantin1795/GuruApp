import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_models.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../data/incomes_api.dart';
import '../data/transfers_api.dart';
import '../domain/aggregated_history_item.dart';
import '../domain/income_operation.dart';
import '../domain/report_operation.dart';
import '../domain/transfer_operation.dart';
import '../providers.dart';
import 'income_detail_screen.dart';
import 'report_detail_stub_screen.dart';
import 'transfer_detail_screen.dart';

/// Объединённая история операций TRANSFER + INCOME (`GET …/operations/history`, ТЗ-06.1).
///
/// Вкладка **pending** должна совпадать с суммой бейджей pending на дашборде: те же правила,
/// что на backend в `TransferAvailableActionsService` / `IncomeAvailableActionsService`
/// (например, `WAITING_24_HOURS` без «подтверждающего» действия в списке pending не попадает).
class AggregatedOperationsHistoryScreen extends ConsumerStatefulWidget {
  final TransferApiScope apiScope;
  final int companyId;

  const AggregatedOperationsHistoryScreen({
    super.key,
    required this.apiScope,
    required this.companyId,
  });

  @override
  ConsumerState<AggregatedOperationsHistoryScreen> createState() =>
      _AggregatedOperationsHistoryScreenState();
}

class _AggregatedOperationsHistoryScreenState extends ConsumerState<AggregatedOperationsHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  IncomeApiScope get _incomeScope =>
      widget.apiScope == TransferApiScope.company ? IncomeApiScope.company : IncomeApiScope.personal;

  CombinedPendingKey get _pendingKey => (scope: widget.apiScope, companyId: widget.companyId);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _invalidatePending() {
    ref.invalidate(combinedOperationsPendingCountProvider(_pendingKey));
    ref.invalidate(transferPendingActionCountProvider((scope: widget.apiScope, companyId: widget.companyId)));
    ref.invalidate(incomePendingActionCountProvider((scope: _incomeScope, companyId: widget.companyId)));
    ref.invalidate(reportPendingActionCountProvider((scope: widget.apiScope, companyId: widget.companyId)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = widget.apiScope == TransferApiScope.personal
        ? l10n.personalWorkspaceTitle
        : companyWorkspaceHeaderRoleLabel(ref, widget.companyId, l10n);

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.dashboardHistory,
      subtitle: l10n.operationsHistorySubtitle,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.operationsHistoryTabPending),
              Tab(text: l10n.operationsHistoryTabAll),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AggregatedHistoryTabBody(
                  key: const PageStorageKey<String>('ops_hist_pending'),
                  tab: UnifiedOperationsHistoryTab.pending,
                  apiScope: widget.apiScope,
                  companyId: widget.companyId,
                  incomeScope: _incomeScope,
                  onInvalidatePending: _invalidatePending,
                ),
                _AggregatedHistoryTabBody(
                  key: const PageStorageKey<String>('ops_hist_all'),
                  tab: UnifiedOperationsHistoryTab.all,
                  apiScope: widget.apiScope,
                  companyId: widget.companyId,
                  incomeScope: _incomeScope,
                  onInvalidatePending: _invalidatePending,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AggregatedHistoryTabBody extends ConsumerStatefulWidget {
  final UnifiedOperationsHistoryTab tab;
  final TransferApiScope apiScope;
  final int companyId;
  final IncomeApiScope incomeScope;
  final VoidCallback onInvalidatePending;

  const _AggregatedHistoryTabBody({
    super.key,
    required this.tab,
    required this.apiScope,
    required this.companyId,
    required this.incomeScope,
    required this.onInvalidatePending,
  });

  @override
  ConsumerState<_AggregatedHistoryTabBody> createState() => _AggregatedHistoryTabBodyState();
}

class _AggregatedHistoryTabBodyState extends ConsumerState<_AggregatedHistoryTabBody> {
  static const _perPage = 20;
  List<AggregatedHistoryItem> _items = const [];
  PaginationInfo? _pagination;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(transfersRepositoryProvider).listUnifiedOperationsHistory(
            scope: widget.apiScope,
            companyId: widget.companyId,
            page: 1,
            perPage: _perPage,
            tab: widget.tab,
          );
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _pagination = page.pagination;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final p = _pagination;
    if (p == null || !p.hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref.read(transfersRepositoryProvider).listUnifiedOperationsHistory(
            scope: widget.apiScope,
            companyId: widget.companyId,
            page: p.page + 1,
            perPage: _perPage,
            tab: widget.tab,
          );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.items];
        _pagination = page.pagination;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _openTransfer(AggregatedHistoryItem row) {
    final t = row.transfer;
    if (t == null) return;
    Navigator.of(context)
        .push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TransferDetailScreen(
          apiScope: widget.apiScope,
          companyId: widget.companyId,
          projectId: t.projectId,
          transferId: t.id,
        ),
      ),
    )
        .then((_) {
      widget.onInvalidatePending();
      _loadFirst();
    });
  }

  void _openIncome(AggregatedHistoryItem row) {
    final inc = row.income;
    if (inc == null) return;
    Navigator.of(context)
        .push<void>(
      MaterialPageRoute<void>(
        builder: (_) => IncomeDetailScreen(
          apiScope: widget.incomeScope,
          companyId: widget.companyId,
          projectId: inc.projectId,
          incomeId: inc.id,
        ),
      ),
    )
        .then((_) {
      widget.onInvalidatePending();
      _loadFirst();
    });
  }

  void _openReport(AggregatedHistoryItem row) {
    final r = row.report;
    if (r == null) return;
    Navigator.of(context)
        .push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReportDetailStubScreen(
          projectId: r.projectId,
          report: r,
        ),
      ),
    )
        .then((_) {
      widget.onInvalidatePending();
      _loadFirst();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_loading) return const AppLoader();
    final err = _error;
    if (err != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(err is ApiException ? err.message : l10n.transfersErrorLoad, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              AppButton(label: l10n.retry, onPressed: _loadFirst),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      final emptyTitle = widget.tab == UnifiedOperationsHistoryTab.pending
          ? l10n.operationsHistoryEmptyPending
          : l10n.operationsHistoryEmpty;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppEmptyState(icon: Icons.layers_outlined, title: emptyTitle),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          ..._items.map(
            (row) {
              if (row.isTransfer && row.transfer != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AggregatedTransferCard(
                    transfer: row.transfer!,
                    onTap: () => _openTransfer(row),
                  ),
                );
              }
              if (row.isIncome && row.income != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AggregatedIncomeCard(
                    income: row.income!,
                    onTap: () => _openIncome(row),
                  ),
                );
              }
              if (row.isReport && row.report != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AggregatedReportCard(
                    report: row.report!,
                    onTap: () => _openReport(row),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          if (_pagination?.hasMore ?? false) ...[
            const SizedBox(height: 8),
            AppButton(
              label: _loadingMore ? l10n.loading : l10n.loadMore,
              onPressed: _loadingMore ? null : _loadMore,
            ),
          ],
        ],
      ),
    );
  }
}

class _AggregatedTransferCard extends StatelessWidget {
  final TransferOperation transfer;
  final VoidCallback onTap;
  static const _accent = Color(0xFF00D6C9);

  const _AggregatedTransferCard({required this.transfer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final projectLine = transfer.projectName?.trim().isNotEmpty == true
        ? transfer.projectName!
        : 'Проект #${transfer.projectId}';

    return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  gradient: LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.09), _accent.withValues(alpha: 0.05)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.operationTransfer,
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45)),
                    ),
                    Text(
                      projectLine,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transfer.receiverName ?? 'Участник #${transfer.receiverProjectParticipantId}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          transfer.amount,
                          style: const TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      transfer.targetType.label,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Chip(label: transfer.status.label),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}

class _AggregatedReportCard extends StatelessWidget {
  final ReportOperation report;
  final VoidCallback onTap;
  static const _accent = Color(0xFF00D6C9);

  const _AggregatedReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final projectLine = report.projectName?.trim().isNotEmpty == true
        ? report.projectName!
        : 'Проект #${report.projectId}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                gradient: LinearGradient(
                  colors: [Colors.white.withValues(alpha: 0.09), _accent.withValues(alpha: 0.07)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.operationReport,
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45)),
                  ),
                  Text(
                    projectLine,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.operationNumber ?? 'REP-${report.id}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        report.customerTotalAmount,
                        style: const TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Chip(label: report.status.label),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AggregatedIncomeCard extends StatelessWidget {
  final IncomeOperation income;
  final VoidCallback onTap;
  static const _accent = Color(0xFF00D6C9);

  const _AggregatedIncomeCard({required this.income, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final projectLine = income.projectName?.trim().isNotEmpty == true
        ? income.projectName!
        : 'Проект #${income.projectId}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                gradient: LinearGradient(
                  colors: [Colors.white.withValues(alpha: 0.09), _accent.withValues(alpha: 0.07)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.operationIncome,
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45)),
                  ),
                  Text(
                    projectLine,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.incomeHistoryCardTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        income.amount,
                        style: const TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Chip(label: income.status.label),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
    );
  }
}
