import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../data/incomes_api.dart';
import '../data/incomes_repository.dart';
import '../domain/income_detail_view.dart';
import '../domain/operation_status.dart';
import '../domain/operation_status_history_entry.dart';
import '../providers.dart';

class IncomeDetailScreen extends ConsumerStatefulWidget {
  final IncomeApiScope apiScope;
  final int companyId;
  final int projectId;
  final int incomeId;

  const IncomeDetailScreen({
    super.key,
    required this.apiScope,
    required this.companyId,
    required this.projectId,
    required this.incomeId,
  });

  @override
  ConsumerState<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

const List<String> _kIncomeActionOrder = [
  'reset_approval',
  'approve_customer',
  'reject_customer',
  'return_to_customer_approval',
  'complete_waiting',
  'rollback_completed',
  'submit_to_customer_approval',
];

class _IncomeDetailScreenState extends ConsumerState<IncomeDetailScreen> {
  IncomeDetailView? _detail;
  String? _error;
  bool _busy = false;
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

  Future<void> _load({bool showFullscreenLoading = false}) async {
    if (!mounted) return;
    final gen = _loadGeneration;
    setState(() {
      _error = null;
      if (showFullscreenLoading) _detail = null;
    });
    try {
      final d = await ref.read(incomesRepositoryProvider).showDetail(
            scope: widget.apiScope,
            companyId: widget.companyId,
            projectId: widget.projectId,
            incomeId: widget.incomeId,
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

  void _replaceRouteAfterSuccessfulAction() {
    FocusManager.instance.primaryFocus?.unfocus();
    final nav = Navigator.of(context);
    final w = widget;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      nav.pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => IncomeDetailScreen(
            apiScope: w.apiScope,
            companyId: w.companyId,
            projectId: w.projectId,
            incomeId: w.incomeId,
          ),
        ),
      );
    });
  }

  Future<void> _runAction(String key) async {
    final needsComment = IncomesRepository.commentRequiredKeys.contains(key);
    String? comment;
    if (needsComment) {
      comment = await _promptComment();
      if (comment == null) return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(incomesRepositoryProvider).performIncomeAction(
            scope: widget.apiScope,
            companyId: widget.companyId,
            projectId: widget.projectId,
            incomeId: widget.incomeId,
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
    final ctrl = TextEditingController();
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.transferActionCommentTitle),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: InputDecoration(hintText: l10n.transferCommentHint),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirm)),
        ],
      ),
    );
    if (ok != true) return null;
    final text = ctrl.text.trim();
    ctrl.dispose();
    return text.isEmpty ? null : text;
  }

  String _actionLabel(BuildContext context, String key) {
    final l10n = context.l10n;
    return switch (key) {
      'reset_approval' => l10n.incomeActionResetApproval,
      'approve_customer' => l10n.incomeActionApprove,
      'reject_customer' => l10n.incomeActionReject,
      'return_to_customer_approval' => l10n.incomeActionReturn,
      'complete_waiting' => l10n.incomeActionCompleteWaiting,
      'rollback_completed' => l10n.incomeActionRollback,
      'submit_to_customer_approval' => l10n.incomeActionSubmit,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName = ref.read(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = widget.apiScope == IncomeApiScope.personal
        ? l10n.personalWorkspaceTitle
        : companyWorkspaceHeaderRoleLabelRead(ref, widget.companyId, l10n);

    final err = _error;
    final detail = _detail;

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.incomeDetailTitle,
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${detail.income.amount} · ${detail.income.status.label}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      if (detail.income.projectName != null)
                        Text(detail.income.projectName!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      if (detail.income.initiatorDisplayName != null)
                        Text(
                          '${l10n.incomeRoleInitiator}: ${detail.income.initiatorDisplayName}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      if (detail.income.projectHeadDisplayName != null)
                        Text(
                          '${l10n.incomeRoleProjectHead}: ${detail.income.projectHeadDisplayName}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      if (detail.income.customerDisplayName != null)
                        Text(
                          '${l10n.incomeRoleCustomer}: ${detail.income.customerDisplayName}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      const SizedBox(height: 16),
                      if (detail.income.comment != null && detail.income.comment!.trim().isNotEmpty)
                        Text(detail.income.comment!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 24),
                      ..._kIncomeActionOrder.where((k) => detail.availableActions[k] == true).map(
                            (k) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppButton(
                                label: _actionLabel(context, k),
                                loading: _busy,
                                onPressed: _busy ? null : () => _runAction(k),
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
                            _historyLine(h),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
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
