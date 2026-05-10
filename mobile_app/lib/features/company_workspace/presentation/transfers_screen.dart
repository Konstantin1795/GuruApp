import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_models.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import 'company_workspace_identity.dart';
import '../../operations/data/transfers_api.dart';
import '../../operations/domain/transfer_recipient_pick.dart';
import '../../operations/domain/transfer_operation.dart';
import '../../operations/domain/transfer_target_type.dart';
import '../../operations/presentation/transfer_detail_screen.dart';
import '../../operations/providers.dart';

class TransfersState {
  final List<TransferOperation> items;
  final PaginationInfo? pagination;
  final bool isLoadingMore;

  const TransfersState({
    required this.items,
    required this.pagination,
    required this.isLoadingMore,
  });

  bool get hasMore => pagination?.hasMore ?? false;

  TransfersState copyWith({
    List<TransferOperation>? items,
    PaginationInfo? pagination,
    bool? isLoadingMore,
  }) =>
      TransfersState(
        items: items ?? this.items,
        pagination: pagination ?? this.pagination,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

typedef TransfersKey = ({TransferApiScope apiScope, int companyId, int projectId});

final transfersControllerProvider =
    StateNotifierProvider.family<TransfersController, AsyncValue<TransfersState>, TransfersKey>(
  (ref, key) => TransfersController(ref: ref, key: key),
);

class TransfersController extends StateNotifier<AsyncValue<TransfersState>> {
  final Ref ref;
  final TransfersKey key;
  static const _perPage = 20;

  TransfersController({required this.ref, required this.key}) : super(const AsyncValue.loading()) {
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    state = const AsyncValue.loading();
    try {
      final page = await ref.read(transfersRepositoryProvider).list(
            scope: key.apiScope,
            companyId: key.companyId,
            projectId: key.projectId,
            page: 1,
            perPage: _perPage,
          );
      state = AsyncValue.data(
        TransfersState(items: page.items, pagination: page.pagination, isLoadingMore: false),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _loadFirstPage();

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final page = await ref.read(transfersRepositoryProvider).list(
            scope: key.apiScope,
            companyId: key.companyId,
            projectId: key.projectId,
            page: (current.pagination?.page ?? 1) + 1,
            perPage: _perPage,
          );
      state = AsyncValue.data(
        TransfersState(
          items: [...current.items, ...page.items],
          pagination: page.pagination,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }
}

class TransfersScreen extends ConsumerWidget {
  final TransferApiScope apiScope;
  final int companyId;
  final int projectId;
  final String projectName;
  final bool canCreateTransfer;

  const TransfersScreen({
    super.key,
    this.apiScope = TransferApiScope.company,
    required this.companyId,
    required this.projectId,
    required this.projectName,
    this.canCreateTransfer = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (apiScope: apiScope, companyId: companyId, projectId: projectId);
    final state = ref.watch(transfersControllerProvider(key));

    final l10n = context.l10n;

    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = apiScope == TransferApiScope.personal
        ? l10n.personalWorkspaceTitle
        : companyWorkspaceHeaderRoleLabel(ref, companyId, l10n);

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.transfersTitle,
      subtitle: projectName,
      actions: [
        if (canCreateTransfer)
          IconButton(
            tooltip: l10n.createTransfer,
            onPressed: () => _openCreate(context, ref, key),
            icon: const Icon(Icons.add),
          ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (e, _) => _ErrorBody(
          message: e is ApiException ? e.message : l10n.transfersErrorLoad,
          onRetry: () => ref.read(transfersControllerProvider(key).notifier).refresh(),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(transfersControllerProvider(key).notifier).refresh(),
          child: data.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    AppEmptyState(
                      icon: Icons.swap_horiz,
                      title: l10n.transfersEmpty,
                      actionLabel: canCreateTransfer ? l10n.createTransfer : null,
                      actionIcon: canCreateTransfer ? Icons.add : null,
                      onAction: canCreateTransfer ? () => _openCreate(context, ref, key) : null,
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    ...data.items.map(
                      (t) => _TransferCard(
                        transfer: t,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TransferDetailScreen(
                                apiScope: apiScope,
                                companyId: companyId,
                                projectId: projectId,
                                transferId: t.id,
                              ),
                            ),
                          ).then((_) {
                            ref.invalidate(
                              transferPendingActionCountProvider(
                                (scope: apiScope, companyId: companyId),
                              ),
                            );
                          });
                        },
                      ),
                    ),
                    if (data.hasMore) ...[
                      const SizedBox(height: 8),
                      AppButton(
                        label: data.isLoadingMore ? l10n.loading : l10n.loadMore,
                        onPressed: data.isLoadingMore
                            ? null
                            : () => ref.read(transfersControllerProvider(key).notifier).loadMore(),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref, TransfersKey key) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateTransferScreen(
          apiScope: key.apiScope,
          companyId: key.companyId,
          projectId: key.projectId,
          projectName: projectName,
        ),
      ),
    );

    if (created == true) {
      await ref.read(transfersControllerProvider(key).notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.transferCreated)),
        );
      }
    }
  }
}

class CreateTransferScreen extends ConsumerStatefulWidget {
  final TransferApiScope apiScope;
  final int companyId;
  final int projectId;
  final String projectName;

  const CreateTransferScreen({
    super.key,
    this.apiScope = TransferApiScope.company,
    required this.companyId,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<CreateTransferScreen> createState() => _CreateTransferScreenState();
}

class _CreateTransferScreenState extends ConsumerState<CreateTransferScreen> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _commentCtrl;
  TransferTargetType _targetType = TransferTargetType.accountableBalance;
  bool _isSubmitting = false;
  late Future<List<TransferRecipientPick>> _recipientsFuture;
  int? _selectedReceiverKey;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _commentCtrl = TextEditingController();
    _recipientsFuture = _loadRecipients();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  int _pickKey(TransferRecipientPick p) => p.projectParticipantId ?? p.counterpartyId ?? 0;

  Future<List<TransferRecipientPick>> _loadRecipients() {
    return ref.read(transfersRepositoryProvider).listRecipients(
          scope: widget.apiScope,
          companyId: widget.companyId,
          projectId: widget.projectId,
          targetType: _targetType,
        );
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
      title: l10n.createTransfer,
      subtitle: widget.projectName,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DropdownButtonFormField<TransferTargetType>(
              key: ValueKey(_targetType),
              initialValue: _targetType,
              decoration: InputDecoration(labelText: context.l10n.transferType),
              items: [
                DropdownMenuItem(
                  value: TransferTargetType.accountableBalance,
                  child: Text(context.l10n.transferTypeAccountable),
                ),
                DropdownMenuItem(
                  value: TransferTargetType.personalBalance,
                  child: Text(context.l10n.transferTypePersonal),
                ),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (TransferTargetType? v) {
                        setState(() {
                          _targetType = v ?? _targetType;
                          _selectedReceiverKey = null;
                          _recipientsFuture = _loadRecipients();
                        });
                      },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TransferRecipientPick>>(
              future: _recipientsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const AppLoader();
                }
                if (snapshot.hasError) {
                  final e = snapshot.error;
                  return _ErrorBody(
                    message: e is ApiException ? e.message : context.l10n.participantsErrorLoad,
                    onRetry: () => setState(() => _recipientsFuture = _loadRecipients()),
                  );
                }

                final picks = snapshot.data ?? const <TransferRecipientPick>[];
                if (picks.isEmpty) {
                  return Center(child: Text(context.l10n.transferNoParticipants));
                }

                _selectedReceiverKey ??= _pickKey(picks.first);
                final selectedKey = _selectedReceiverKey!;
                TransferRecipientPick pickForKey(int k) =>
                    picks.firstWhere((p) => _pickKey(p) == k, orElse: () => picks.first);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    DropdownButtonFormField<int>(
                      key: ValueKey<int>(selectedKey),
                      initialValue: selectedKey,
                      decoration: InputDecoration(labelText: context.l10n.transferReceiver),
                      items: picks
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: _pickKey(p),
                              child: Text(p.label),
                            ),
                          )
                          .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (id) {
                              if (id == null) return;
                              setState(() => _selectedReceiverKey = id);
                            },
                    ),
                    const SizedBox(height: 12),
                    AppInput(
                      controller: _amountCtrl,
                      label: context.l10n.transferAmountLabel,
                      hint: context.l10n.transferAmountHint,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    AppInput(
                      controller: _commentCtrl,
                      label: context.l10n.transferCommentLabel,
                      hint: context.l10n.transferCommentHint,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: context.l10n.createTransfer,
                      loading: _isSubmitting,
                      onPressed: _isSubmitting
                          ? null
                          : () => _submit(pickForKey(selectedKey)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(TransferRecipientPick pick) async {
    final amount = _amountCtrl.text.trim().replaceAll(',', '.');
    if (!RegExp(r'^(?!0+(?:\.0{1,2})?$)\d+(?:\.\d{1,2})?$').hasMatch(amount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.transferAmountError)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(transfersRepositoryProvider).create(
            scope: widget.apiScope,
            companyId: widget.companyId,
            projectId: widget.projectId,
            receiverProjectParticipantId: pick.projectParticipantId,
            receiverCounterpartyId: pick.counterpartyId,
            targetType: _targetType,
            amount: amount,
            comment: _commentCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e, context.l10n.transferErrorCreate))),
      );
    }
  }
}

class _TransferCard extends StatelessWidget {
  final TransferOperation transfer;
  final VoidCallback onTap;
  static const _accent = Color(0xFF00D6C9);

  const _TransferCard({required this.transfer, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                        if (transfer.comment != null && transfer.comment!.trim().isNotEmpty)
                          _Chip(label: transfer.comment!.trim()),
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

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(label: context.l10n.retry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// Returns the most specific human-readable error message from an API error.
/// Prefers field-level messages (first field, first message) over the general
/// message, falling back to [fallback] for unexpected error types.
String _friendlyError(Object e, String fallback) {
  if (e is ApiException) {
    final fields = e.fields;
    if (fields != null && fields.isNotEmpty) {
      final firstValue = fields.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }
      if (firstValue is String && firstValue.isNotEmpty) return firstValue;
    }
    return e.message.isNotEmpty ? e.message : fallback;
  }
  return fallback;
}
