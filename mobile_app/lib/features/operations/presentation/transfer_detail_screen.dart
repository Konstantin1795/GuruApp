import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../data/transfers_api.dart';
import '../data/transfers_repository.dart';
import '../domain/operation_status.dart';
import '../domain/operation_status_history_entry.dart';
import '../domain/transfer_detail_view.dart';
import '../providers.dart';
import 'attach_report_to_transfer_sheet.dart';
import 'operation_comment_dialog.dart';

class TransferDetailScreen extends ConsumerStatefulWidget {
  final TransferApiScope apiScope;
  final int companyId;
  final int projectId;
  final int transferId;

  const TransferDetailScreen({
    super.key,
    required this.apiScope,
    required this.companyId,
    required this.projectId,
    required this.transferId,
  });

  @override
  ConsumerState<TransferDetailScreen> createState() => _TransferDetailScreenState();
}

const List<String> _kActionOrder = [
  'approve_project_head',
  'reject_project_head',
  'reset_approval',
  'submit_for_approval',
  'complete_immediate',
  'return_to_created',
  'return_to_project_head_approval',
  'complete_waiting',
  'rollback_completed',
  'return_completed_to_project_head_approval',
];

class _TransferDetailScreenState extends ConsumerState<TransferDetailScreen> {
  TransferDetailView? _detail;
  String? _error;
  bool _busy = false;

  /// Поколение загрузки: после [pushReplacement] старый экран уничтожается, но ответ API может прийти позже —
  /// без проверки возможен краткий красный экран из‑за [setState]/layout на уже недействительном дереве.
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load(showFullscreenLoading: false);
  }

  @override
  void dispose() {
    _loadGeneration++;
    super.dispose();
  }

  /// [showFullscreenLoading] — только при первом входе / «Повторить».
  Future<void> _load({bool showFullscreenLoading = false}) async {
    if (!mounted) return;
    final gen = _loadGeneration;
    setState(() {
      _error = null;
      if (showFullscreenLoading) _detail = null;
    });
    try {
      final d = await ref.read(transfersRepositoryProvider).showDetail(
            scope: widget.apiScope,
            companyId: widget.companyId,
            projectId: widget.projectId,
            transferId: widget.transferId,
          );
      if (!mounted || gen != _loadGeneration) return;
      setState(() => _detail = d);
    } catch (e) {
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _error = e is ApiException ? e.message : '_generic';
      });
    }
  }

  Future<void> _openAttachToReport(TransferDetailView detail) async {
    final num = detail.transfer.operationNumber?.trim();
    if (num == null || num.isEmpty) return;
    final linkedId = detail.linkedReport?.isLinked == true ? detail.linkedReport!.reportId : null;
    final ok = await showAttachReportToTransferSheet(
      context,
      apiScope: widget.apiScope,
      companyId: widget.companyId,
      projectId: widget.projectId,
      transferOperationNumber: num,
      excludeReportIdLinked: linkedId,
    );
    if (ok && mounted) {
      await _load(showFullscreenLoading: false);
    }
  }

  /// Замена route на следующем кадре — не снимаем текущий route в том же потоке, что завершает обработчик кнопки.
  void _replaceRouteAfterSuccessfulAction() {
    FocusManager.instance.primaryFocus?.unfocus();
    final nav = Navigator.of(context);
    final w = widget;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      nav.pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => TransferDetailScreen(
            apiScope: w.apiScope,
            companyId: w.companyId,
            projectId: w.projectId,
            transferId: w.transferId,
          ),
        ),
      );
    });
  }

  Future<void> _runAction(String key) async {
    final needsComment = TransfersRepository.commentRequiredKeys.contains(key);
    String? comment;
    if (needsComment) {
      comment = await _promptComment();
      if (comment == null) return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(transfersRepositoryProvider).performTransferAction(
            scope: widget.apiScope,
            companyId: widget.companyId,
            projectId: widget.projectId,
            transferId: widget.transferId,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName = ref.read(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = widget.apiScope == TransferApiScope.personal
        ? l10n.personalWorkspaceTitle
        : companyWorkspaceHeaderRoleLabelRead(ref, widget.companyId, l10n);

    final err = _error;
    final detail = _detail;

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.transferDetailTitle,
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
          : detail == null
              ? const AppLoader()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final minH =
                        constraints.hasBoundedHeight ? constraints.maxHeight.clamp(0.0, double.infinity) : 0.0;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minH),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '${detail.transfer.receiverName ?? '—'} · ${detail.transfer.amount}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${detail.transfer.targetType.label} · ${detail.transfer.status.label}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                                ),
                                if (detail.transfer.comment != null &&
                                    detail.transfer.comment!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(detail.transfer.comment!.trim()),
                                ],
                                if (detail.linkedReport != null && detail.linkedReport!.isLinked) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.transferLinkedToReport(
                                      detail.linkedReport!.operationNumber?.trim().isNotEmpty == true
                                          ? detail.linkedReport!.operationNumber!.trim()
                                          : 'REP-${detail.linkedReport!.reportId}',
                                    ),
                                    style: TextStyle(
                                      color: Colors.lightBlueAccent.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if (detail.linkedReport == null || !detail.linkedReport!.isLinked) ...[
                                  const SizedBox(height: 12),
                                  AppButton(
                                    label: l10n.transferAttachToReportButton,
                                    onPressed: () => _openAttachToReport(detail),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                Text(l10n.transferLifecycleTitle,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                const SizedBox(height: 10),
                                ...detail.statusHistory.map((h) => _HistoryTile(entry: h, l10n: l10n)),
                                const SizedBox(height: 20),
                                IgnorePointer(
                                  ignoring: _busy,
                                  child: Opacity(
                                    opacity: _busy ? 0.45 : 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: _buildActions(context, detail),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_busy)
                              Positioned.fill(
                                child: AbsorbPointer(
                                  child: DecoratedBox(
                                    decoration:
                                        BoxDecoration(color: Colors.black.withValues(alpha: 0.12)),
                                    child: const Center(child: AppLoader()),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  List<Widget> _buildActions(BuildContext context, TransferDetailView detail) {
    final keys = detail.availableActions.entries.where((e) => e.value).map((e) => e.key).toList();
    keys.sort((a, b) {
      final ia = _kActionOrder.indexOf(a);
      final ib = _kActionOrder.indexOf(b);
      final ra = ia < 0 ? 999 : ia;
      final rb = ib < 0 ? 999 : ib;
      return ra.compareTo(rb);
    });

    return [
      for (final k in keys)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppButton(
            label: _actionLabel(context.l10n, k),
            onPressed: () => _runAction(k),
          ),
        ),
    ];
  }
}

class _HistoryTile extends StatelessWidget {
  final OperationStatusHistoryEntry entry;
  final AppLocalizations l10n;

  const _HistoryTile({required this.entry, required this.l10n});

  String _statusLabel(String raw) {
    try {
      return OperationStatus.fromJson(raw).label;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = entry.fromStatus;
    final arrow = from != null ? '${_statusLabel(from)} → ${_statusLabel(entry.toStatus)}' : _statusLabel(entry.toStatus);
    final who = entry.authorFullName?.trim().isNotEmpty == true
        ? entry.authorFullName!
        : l10n.transferHistoryAuthorSystem;
    final when = entry.createdAt != null ? _fmt(entry.createdAt!) : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(arrow, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('$who · $when', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
          if (entry.comment != null && entry.comment!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(entry.comment!.trim()),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}.${two(l.month)}.${l.year} ${two(l.hour)}:${two(l.minute)}';
  }
}

String _actionLabel(AppLocalizations l10n, String key) {
  return switch (key) {
    'approve_project_head' => l10n.transferActionApproveProjectHead,
    'reject_project_head' => l10n.transferActionRejectProjectHead,
    'reset_approval' => l10n.transferActionResetApproval,
    'submit_for_approval' => l10n.transferActionSubmitForApproval,
    'complete_immediate' => l10n.transferActionCompleteImmediate,
    'return_to_created' => l10n.transferActionReturnToCreated,
    'return_to_project_head_approval' => l10n.transferActionReturnToProjectHeadApproval,
    'complete_waiting' => l10n.transferActionCompleteWaiting,
    'rollback_completed' => l10n.transferActionRollbackCompleted,
    'return_completed_to_project_head_approval' => l10n.transferActionReturnCompletedToProjectHeadApproval,
    _ => key,
  };
}
