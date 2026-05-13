import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../data/reports_repository.dart';
import '../data/transfers_api.dart' show TransferApiScope;
import '../domain/operation_status.dart';
import '../domain/operation_status_history_entry.dart';
import '../domain/report_detail_view.dart';
import '../providers.dart';
import 'attach_transfer_to_report_sheet.dart';
import 'operation_comment_dialog.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final TransferApiScope apiScope;
  final int companyId;
  final int projectId;
  final int reportId;

  const ReportDetailScreen({
    super.key,
    required this.apiScope,
    required this.companyId,
    required this.projectId,
    required this.reportId,
  });

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

const List<String> _kReportActionOrder = [
  'submit',
  'approve_supervisor',
  'reject_supervisor',
  'approve_project_head',
  'reject_project_head',
  'approve_customer',
  'reject_customer',
  'complete_waiting',
  'rollback_completed',
];

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen>
    with SingleTickerProviderStateMixin {
  ReportDetailView? _detail;
  String? _error;
  bool _busy = false;
  int _loadGeneration = 0;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _load(showFullscreenLoading: false);
  }

  @override
  void dispose() {
    _loadGeneration++;
    _tabController?.dispose();
    super.dispose();
  }

  void _syncTabs(bool customerView) {
    final len = customerView ? 1 : 2;
    if (_tabController == null || _tabController!.length != len) {
      _tabController?.dispose();
      _tabController = TabController(length: len, vsync: this);
    }
  }

  Future<void> _load({bool showFullscreenLoading = false}) async {
    if (!mounted) return;
    final gen = _loadGeneration;
    setState(() {
      _error = null;
      if (showFullscreenLoading) _detail = null;
    });
    try {
      final d = await ref.read(reportsRepositoryProvider).showDetail(
            scope: widget.apiScope,
            companyId: widget.companyId,
            projectId: widget.projectId,
            reportId: widget.reportId,
          );
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _detail = d;
        _syncTabs(d.viewerContext == 'customer');
      });
    } catch (e) {
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _error = e is ApiException ? e.message : '_generic';
      });
    }
  }

  void _replaceRouteAfterSuccessfulAction() {
    FocusManager.instance.primaryFocus?.unfocus();
    final nav = Navigator.of(context);
    final w = widget;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      nav.pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => ReportDetailScreen(
            apiScope: w.apiScope,
            companyId: w.companyId,
            projectId: w.projectId,
            reportId: w.reportId,
          ),
        ),
      );
    });
  }

  Future<void> _runAction(String key) async {
    final needsComment = ReportsRepository.commentRequiredKeys.contains(key);
    String? comment;
    if (needsComment) {
      comment = await _promptComment();
      if (comment == null) return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(reportsRepositoryProvider).performReportAction(
            scope: widget.apiScope,
            companyId: widget.companyId,
            projectId: widget.projectId,
            reportId: widget.reportId,
            actionKey: key,
            comment: comment,
          );
      if (!mounted) return;
      _replaceRouteAfterSuccessfulAction();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : context.l10n.transferActionError),
        ),
      );
    }
  }

  Future<String?> _promptComment() async {
    final text = await showOperationCommentDialog(context, context.l10n);
    if (text == null) return null;
    final t = text.trim();
    return t.isEmpty ? null : t;
  }

  String _actionLabel(BuildContext context, String key) {
    final l10n = context.l10n;
    return switch (key) {
      'submit' => l10n.reportActionSubmit,
      'approve_supervisor' => l10n.reportActionApproveSupervisor,
      'reject_supervisor' => l10n.reportActionRejectSupervisor,
      'approve_project_head' => l10n.reportActionApproveProjectHead,
      'reject_project_head' => l10n.reportActionRejectProjectHead,
      'approve_customer' => l10n.reportActionApproveCustomer,
      'reject_customer' => l10n.reportActionRejectCustomer,
      'complete_waiting' => l10n.reportActionCompleteWaiting,
      'rollback_completed' => l10n.reportActionRollbackCompleted,
      _ => key,
    };
  }

  String _reportTitle(ReportDetailView d) {
    final num = d.report['operation_number']?.toString();
    if (num != null && num.isNotEmpty) return '№ $num';
    return 'ID ${widget.reportId}';
  }

  OperationStatus _readStatus(ReportDetailView d) {
    try {
      return OperationStatus.fromJson((d.report['operation_status'] ?? '').toString());
    } catch (_) {
      return OperationStatus.created;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName = ref.read(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = widget.apiScope == TransferApiScope.personal
        ? l10n.personalWorkspaceTitle
        : companyWorkspaceHeaderRoleLabelRead(ref, widget.companyId, l10n);

    final err = _error;
    final detail = _detail;
    final tabs = _tabController;

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.reportDetailTitle,
      actions: detail != null && err == null
          ? [
              IconButton(
                tooltip: l10n.retry,
                onPressed: _busy ? null : () => _load(showFullscreenLoading: false),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ]
          : null,
      body: err != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      err == '_generic' || err.isEmpty ? l10n.transferDetailErrorLoad : err,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    AppButton(label: l10n.retry, onPressed: () => _load(showFullscreenLoading: true)),
                  ],
                ),
              ),
            )
          : detail == null || tabs == null
              ? const AppLoader()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _reportTitle(detail),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _readStatus(detail).label,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                            ),
                            if (detail.report['project_name'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  detail.report['project_name'].toString(),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                                ),
                              ),
                            if (detail.report['operation_date'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  detail.report['operation_date'].toString(),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (tabs.length == 2) ...[
                      TabBar(
                        controller: tabs,
                        tabs: [
                          Tab(text: l10n.reportTabDetails),
                          Tab(text: l10n.reportTabTransfers),
                        ],
                      ),
                    ],
                    Expanded(
                      child: tabs.length == 1
                          ? _ReportDetailsBody(
                              detail: detail,
                              busy: _busy,
                              onAction: _runAction,
                              actionLabel: _actionLabel,
                              historyLine: _historyLine,
                            )
                          : TabBarView(
                              controller: tabs,
                              children: [
                                _ReportDetailsBody(
                                  detail: detail,
                                  busy: _busy,
                                  onAction: _runAction,
                                  actionLabel: _actionLabel,
                                  historyLine: _historyLine,
                                ),
                                _ReportTransfersBody(
                                  detail: detail,
                                  apiScope: widget.apiScope,
                                  companyId: widget.companyId,
                                  projectId: widget.projectId,
                                  reportId: widget.reportId,
                                  onLinksChanged: () => _load(showFullscreenLoading: false),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _ReportDetailsBody extends StatelessWidget {
  final ReportDetailView detail;
  final bool busy;
  final Future<void> Function(String key) onAction;
  final String Function(BuildContext context, String key) actionLabel;
  final String Function(OperationStatusHistoryEntry h) historyLine;

  const _ReportDetailsBody({
    required this.detail,
    required this.busy,
    required this.onAction,
    required this.actionLabel,
    required this.historyLine,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = detail.report;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r['customer_total_amount'] != null)
            Text(
              '${l10n.reportCustomerTotal}: ${r['customer_total_amount']}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          if (r['recipient_amount'] != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.reportRecipientTotal}: ${r['recipient_amount']}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
          if (r['profit_amount'] != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.reportProfit}: ${r['profit_amount']}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
          if (r['comment'] != null && r['comment'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(r['comment'].toString(), style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
          ],
          if (r['lines'] is List && (r['lines'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.reportLinesTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final line in (r['lines'] as List))
              if (line is Map)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _lineSummary(line.cast<String, dynamic>()),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ),
          ],
          const SizedBox(height: 20),
          ..._kReportActionOrder.where((k) => detail.availableActions[k] == true).map(
                (k) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppButton(
                    label: actionLabel(context, k),
                    loading: busy,
                    onPressed: busy ? null : () => onAction(k),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          Text(l10n.dashboardHistory, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...detail.statusHistory.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                historyLine(h),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _lineSummary(Map<String, dynamic> line) {
    final name = line['name']?.toString() ?? '';
    final qty = line['quantity']?.toString() ?? '';
    final ru = line['recipient_unit_price'];
    final cu = line['customer_unit_price'];
    final parts = <String>[name, '×$qty'];
    if (ru != null) parts.add('R:$ru');
    if (cu != null) parts.add('C:$cu');
    return parts.join(' · ');
  }
}

class _ReportTransfersBody extends ConsumerStatefulWidget {
  final ReportDetailView detail;
  final TransferApiScope apiScope;
  final int companyId;
  final int projectId;
  final int reportId;
  final VoidCallback onLinksChanged;

  const _ReportTransfersBody({
    required this.detail,
    required this.apiScope,
    required this.companyId,
    required this.projectId,
    required this.reportId,
    required this.onLinksChanged,
  });

  @override
  ConsumerState<_ReportTransfersBody> createState() => _ReportTransfersBodyState();
}

class _ReportTransfersBodyState extends ConsumerState<_ReportTransfersBody> {
  bool _busy = false;

  Set<String> get _excludeNums {
    final s = <String>{};
    for (final link in widget.detail.transferLinks) {
      final t = link['transfer'];
      if (t is Map) {
        final n = t['operation_number']?.toString().trim();
        if (n != null && n.isNotEmpty) {
          s.add(n);
        }
      }
    }
    return s;
  }

  Future<void> _openAttach() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await showAttachTransferToReportSheet(
        context,
        apiScope: widget.apiScope,
        companyId: widget.companyId,
        projectId: widget.projectId,
        reportId: widget.reportId,
        excludeOperationNumbers: _excludeNums,
      );
      if (ok && mounted) widget.onLinksChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detail = widget.detail;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        AppButton(
          label: l10n.reportAttachTransferButton,
          loading: _busy,
          onPressed: _busy ? null : _openAttach,
        ),
        const SizedBox(height: 16),
        if (detail.transferLinks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.reportTransfersEmpty,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
            ),
          )
        else
          for (final link in detail.transferLinks)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _ReportTransfersBodyState._formatTransferLink(link),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
              ),
            ),
      ],
    );
  }

  static String _formatTransferLink(Map<String, dynamic> link) {
    final t = link['transfer'];
    if (t is! Map) {
      return link.toString();
    }
    final m = t.cast<String, dynamic>();
    final num = m['operation_number']?.toString() ?? '';
    final amt = m['amount']?.toString() ?? '';
    final st = m['operation_status']?.toString() ?? '';
    return '$num · $amt · $st';
  }
}

String _historyLine(OperationStatusHistoryEntry h) {
  final from = h.fromStatus != null ? _safeStatusLabel(h.fromStatus!) : null;
  final to = _safeStatusLabel(h.toStatus);
  final transition = from != null ? '$from → $to' : to;
  final author = (h.authorFullName ?? '').trim();
  final authorPart = author.isEmpty ? '' : ' · $author';
  final comment = (h.comment ?? '').trim();
  final commentPart = comment.isEmpty ? '' : ' · $comment';
  final date = h.createdAt != null ? '${h.createdAt!.toLocal()} · ' : '';
  return '$date$transition$authorPart$commentPart';
}

String _safeStatusLabel(String code) {
  try {
    return OperationStatus.fromJson(code).label;
  } catch (_) {
    return code;
  }
}
