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
import '../data/transfers_api.dart';
import '../domain/transfer_operation.dart';
import '../providers.dart';
import 'transfer_detail_screen.dart';

class AggregatedTransfersHistoryScreen extends ConsumerStatefulWidget {
  final TransferApiScope apiScope;
  final int companyId;

  const AggregatedTransfersHistoryScreen({
    super.key,
    required this.apiScope,
    required this.companyId,
  });

  @override
  ConsumerState<AggregatedTransfersHistoryScreen> createState() =>
      _AggregatedTransfersHistoryScreenState();
}

class _AggregatedTransfersHistoryScreenState extends ConsumerState<AggregatedTransfersHistoryScreen> {
  static const _perPage = 20;
  List<TransferOperation> _items = const [];
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
      final page = await ref.read(transfersRepositoryProvider).listHistoryAggregated(
            scope: widget.apiScope,
            companyId: widget.companyId,
            page: 1,
            perPage: _perPage,
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
      final page = await ref.read(transfersRepositoryProvider).listHistoryAggregated(
            scope: widget.apiScope,
            companyId: widget.companyId,
            page: p.page + 1,
            perPage: _perPage,
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

  void _openTransfer(TransferOperation t) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransferDetailScreen(
          apiScope: widget.apiScope,
          companyId: widget.companyId,
          projectId: t.projectId,
          transferId: t.id,
        ),
      ),
    ).then((_) {
      ref.invalidate(transferPendingActionCountProvider(
        (scope: widget.apiScope, companyId: widget.companyId),
      ));
      _loadFirst();
    });
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
      subtitle: l10n.transferHistoryAllProjects,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppEmptyState(icon: Icons.swap_horiz, title: l10n.transfersEmpty),
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
            (t) => _AggregatedTransferCard(
              transfer: t,
              onTap: () => _openTransfer(t),
            ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
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
