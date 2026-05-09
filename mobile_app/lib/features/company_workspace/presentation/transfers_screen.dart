import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_models.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../operations/domain/transfer_operation.dart';
import '../../operations/domain/transfer_target_type.dart';
import '../../operations/providers.dart';
import '../../projects/domain/project_participant.dart';
import '../../projects/providers.dart';

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

typedef TransfersKey = ({int companyId, int projectId});

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

  Future<void> create({
    required int receiverProjectParticipantId,
    required TransferTargetType targetType,
    required String amount,
    String? comment,
  }) async {
    await ref.read(transfersRepositoryProvider).create(
          companyId: key.companyId,
          projectId: key.projectId,
          receiverProjectParticipantId: receiverProjectParticipantId,
          targetType: targetType,
          amount: amount,
          comment: comment,
        );
    await refresh();
  }
}

class TransfersScreen extends ConsumerWidget {
  final int companyId;
  final int projectId;
  final String projectName;

  const TransfersScreen({
    super.key,
    required this.companyId,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (companyId: companyId, projectId: projectId);
    final state = ref.watch(transfersControllerProvider(key));

    return AppScaffold(
      title: 'Переводы',
      subtitle: projectName,
      actions: [
        IconButton(
          tooltip: 'Создать перевод',
          onPressed: () => _openCreate(context, ref, key),
          icon: const Icon(Icons.add),
        ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (e, _) => _ErrorBody(
          message: e is ApiException ? e.message : 'Не удалось загрузить переводы',
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
                      title: 'Переводов пока нет',
                      actionLabel: 'Создать перевод',
                      actionIcon: Icons.add,
                      onAction: () => _openCreate(context, ref, key),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    ...data.items.map((t) => _TransferCard(transfer: t)),
                    if (data.hasMore) ...[
                      const SizedBox(height: 8),
                      AppButton(
                        label: data.isLoadingMore ? 'Загрузка...' : 'Загрузить ещё',
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
          const SnackBar(content: Text('Перевод создан')),
        );
      }
    }
  }
}

class CreateTransferScreen extends ConsumerStatefulWidget {
  final int companyId;
  final int projectId;
  final String projectName;

  const CreateTransferScreen({
    super.key,
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
  ProjectParticipant? _receiver;
  TransferTargetType _targetType = TransferTargetType.accountableBalance;
  bool _isSubmitting = false;
  late Future<List<ProjectParticipant>> _participantsFuture;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _commentCtrl = TextEditingController();
    _participantsFuture = _loadParticipants();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<List<ProjectParticipant>> _loadParticipants() async {
    final repo = ref.read(projectParticipantsRepositoryProvider);
    final items = await repo.list(companyId: widget.companyId, projectId: widget.projectId);
    return items.where((p) => p.isActive).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Создать перевод',
      subtitle: widget.projectName,
      body: FutureBuilder<List<ProjectParticipant>>(
        future: _participantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final e = snapshot.error;
            return _ErrorBody(
              message: e is ApiException ? e.message : 'Не удалось загрузить участников',
              onRetry: () => setState(() => _participantsFuture = _loadParticipants()),
            );
          }

          final participants = snapshot.data ?? const <ProjectParticipant>[];
          if (participants.isEmpty) {
            return const Center(child: Text('Нет участников для перевода'));
          }
          _receiver ??= participants.first;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<int>(
                initialValue: _receiver?.id,
                decoration: const InputDecoration(labelText: 'Получатель'),
                items: participants
                    .map(
                      (p) => DropdownMenuItem<int>(
                        value: p.id,
                        child: Text('${p.displayName} · ${_roleLabel(p.role)}'),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (id) {
                        if (id == null) return;
                        setState(() => _receiver = participants.firstWhere((p) => p.id == id));
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TransferTargetType>(
                initialValue: _targetType,
                decoration: const InputDecoration(labelText: 'Тип перевода'),
                items: TransferTargetType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _targetType = value ?? _targetType),
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _amountCtrl,
                label: 'Сумма',
                hint: '10000.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _commentCtrl,
                label: 'Комментарий',
                hint: 'Подотчёт на закупку',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 18),
              AppButton(
                label: _isSubmitting ? 'Создание...' : 'Создать перевод',
                loading: _isSubmitting,
                onPressed: _isSubmitting ? null : () => _submit(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    final receiver = _receiver;
    final amount = _amountCtrl.text.trim().replaceAll(',', '.');
    if (receiver == null) return;
    if (!RegExp(r'^(?!0+(?:\.0{1,2})?$)\d+(?:\.\d{1,2})?$').hasMatch(amount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите сумму больше 0, до 2 знаков после точки')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(transfersRepositoryProvider).create(
            companyId: widget.companyId,
            projectId: widget.projectId,
            receiverProjectParticipantId: receiver.id,
            targetType: _targetType,
            amount: amount,
            comment: _commentCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e, 'Не удалось создать перевод'))),
      );
    }
  }
}

class _TransferCard extends StatelessWidget {
  final TransferOperation transfer;
  static const _accent = Color(0xFF00D6C9);

  const _TransferCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
            AppButton(label: 'Повторить', onPressed: onRetry),
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

String _roleLabel(String role) => switch (role) {
      'PROJECT_HEAD' => 'Руководитель',
      'PARTNER' => 'Партнёр',
      'CUSTOMER' => 'Заказчик',
      'SUPERVISOR' => 'Куратор',
      'EMPLOYEE' => 'Сотрудник',
      'SUPPLIER' => 'Поставщик',
      'CONTRACTOR' => 'Подрядчик',
      _ => role,
    };
