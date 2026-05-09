import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../counterparties/domain/counterparty.dart';
import '../../counterparties/providers.dart';
import '../../projects/domain/project.dart';
import '../../projects/domain/project_participant.dart';
import 'participant_wallet_screen.dart';
import 'transfers_screen.dart';
import '../../projects/providers.dart';

// ─────────────────────────── State / Controller ────────────────────────────

class ProjectParticipantsState {
  final List<ProjectParticipant> items;

  const ProjectParticipantsState({required this.items});

  ProjectParticipantsState copyWith({List<ProjectParticipant>? items}) =>
      ProjectParticipantsState(items: items ?? this.items);
}

class ProjectParticipantsController
    extends StateNotifier<AsyncValue<ProjectParticipantsState>> {
  final int companyId;
  final int projectId;
  final Ref ref;

  ProjectParticipantsController({
    required this.companyId,
    required this.projectId,
    required this.ref,
  }) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(projectParticipantsRepositoryProvider);
      final items = await repo.list(companyId: companyId, projectId: projectId);
      state = AsyncValue.data(ProjectParticipantsState(items: items));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> add({required int counterpartyId, required String role}) async {
    final repo = ref.read(projectParticipantsRepositoryProvider);
    await repo.add(
      companyId: companyId,
      projectId: projectId,
      counterpartyId: counterpartyId,
      role: role,
    );
    await _load();
  }

  Future<void> updateParticipantRole({
    required int participantId,
    required String role,
  }) async {
    final repo = ref.read(projectParticipantsRepositoryProvider);
    await repo.updateRole(
      companyId: companyId,
      projectId: projectId,
      participantId: participantId,
      role: role,
    );
    await _load();
  }

  Future<void> removeParticipant({required int participantId}) async {
    final repo = ref.read(projectParticipantsRepositoryProvider);
    await repo.remove(
      companyId: companyId,
      projectId: projectId,
      participantId: participantId,
    );
    await _load();
  }
}

typedef _ParticipantsKey = ({int companyId, int projectId});

final projectParticipantsControllerProvider = StateNotifierProvider.family<
    ProjectParticipantsController,
    AsyncValue<ProjectParticipantsState>,
    _ParticipantsKey>(
  (ref, key) => ProjectParticipantsController(
    companyId: key.companyId,
    projectId: key.projectId,
    ref: ref,
  ),
);

// ───────────────────────────── Main Screen ─────────────────────────────────

class ProjectParticipantsScreen extends ConsumerWidget {
  final Project project;
  final int companyId;

  const ProjectParticipantsScreen({
    super.key,
    required this.project,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (companyId: companyId, projectId: project.id);
    final state = ref.watch(projectParticipantsControllerProvider(key));

    return AppScaffold(
      title: 'Участники',
      subtitle: project.name,
      actions: [
        IconButton(
          icon: const Icon(Icons.swap_horiz),
          tooltip: 'Переводы',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TransfersScreen(
                companyId: companyId,
                projectId: project.id,
                projectName: project.name,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.person_add_alt_1_outlined),
          tooltip: 'Добавить участника',
          onPressed: () => _showAddDialog(context, ref, key, state.valueOrNull?.items ?? []),
        ),
      ],
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: e is ApiException ? e.message : 'Не удалось загрузить участников',
          onRetry: () =>
              ref.read(projectParticipantsControllerProvider(key).notifier).refresh(),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () =>
              ref.read(projectParticipantsControllerProvider(key).notifier).refresh(),
          child: data.items.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: _EmptyBody(
                          onAdd: () => _showAddDialog(context, ref, key, []),
                        ),
                      ),
                    );
                  },
                )
              : _ParticipantsList(
                  companyId: companyId,
                  projectId: project.id,
                  items: data.items,
                  onAdd: () =>
                      _showAddDialog(context, ref, key, data.items),
                ),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    _ParticipantsKey key,
    List<ProjectParticipant> existingParticipants,
  ) async {
    final added = await showAddProjectParticipantDialog(
      context: context,
      ref: ref,
      companyId: companyId,
      existingParticipants: existingParticipants,
      onAdd: ({required counterpartyId, required role}) async {
        await ref.read(projectParticipantsControllerProvider(key).notifier).add(
              counterpartyId: counterpartyId,
              role: role,
            );
      },
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Участник добавлен')));
    }
  }
}

// ─────────────────────────── Sort / labels ─────────────────────────────────

int _projectRoleSortOrder(String role) {
  switch (role) {
    case 'PROJECT_HEAD':
      return 0;
    case 'PARTNER':
      return 1;
    case 'SUPERVISOR':
      return 2;
    case 'EMPLOYEE':
      return 3;
    case 'CUSTOMER':
      return 4;
    default:
      return 99;
  }
}

List<ProjectParticipant> _sortedParticipants(List<ProjectParticipant> items) {
  final list = List<ProjectParticipant>.from(items);
  list.sort((a, b) {
    final byRole = _projectRoleSortOrder(a.role).compareTo(_projectRoleSortOrder(b.role));
    if (byRole != 0) return byRole;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });
  return list;
}

String _projectRoleTitleRu(String code) {
  const labels = {
    'PROJECT_HEAD': 'Руководитель проекта',
    'PARTNER': 'Партнёр',
    'CUSTOMER': 'Заказчик',
    'SUPERVISOR': 'Куратор',
    'EMPLOYEE': 'Сотрудник',
    'SUPPLIER': 'Поставщик',
    'CONTRACTOR': 'Подрядчик',
  };
  return labels[code] ?? code;
}

const _manualProjectRoles = {'PARTNER', 'SUPERVISOR', 'EMPLOYEE'};

class _ParticipantsList extends StatelessWidget {
  final int companyId;
  final int projectId;
  final List<ProjectParticipant> items;
  final VoidCallback onAdd;

  const _ParticipantsList({
    required this.companyId,
    required this.projectId,
    required this.items,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedParticipants(items);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${items.length} ${_participantWord(items.length)}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            // AppButton — full width через infinity; в Row нужна фикс. ширина (как на экране контрагентов).
            SizedBox(
              width: 132,
              child: AppButton(
                label: 'Добавить',
                icon: Icons.person_add_alt_1_outlined,
                onPressed: onAdd,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sorted.map(
          (p) => _ParticipantTile(
            companyId: companyId,
            projectId: projectId,
            participant: p,
          ),
        ),
      ],
    );
  }

  static String _participantWord(int n) {
    if (n % 100 >= 11 && n % 100 <= 19) return 'участников';
    switch (n % 10) {
      case 1:
        return 'участник';
      case 2:
      case 3:
      case 4:
        return 'участника';
      default:
        return 'участников';
    }
  }
}

class _ParticipantTile extends ConsumerWidget {
  final int companyId;
  final int projectId;
  final ProjectParticipant participant;
  static const _accent = Color(0xFF00D6C9);

  const _ParticipantTile({
    required this.companyId,
    required this.projectId,
    required this.participant,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (companyId: companyId, projectId: projectId);
    final canEditRole = _manualProjectRoles.contains(participant.role);
    final canDelete = participant.role != 'PROJECT_HEAD';
    final hasMenu = canEditRole || canDelete;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ParticipantWalletScreen(
              participant: participant,
              companyId: companyId,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.09),
                  _accent.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _projectRoleTitleRu(participant.role),
                        style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        participant.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (participant.email != null && participant.email!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          participant.email!.trim(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _LevelChip(level: participant.level),
                          if (!participant.isActive)
                            Text(
                              'неактивен',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasMenu)
                  PopupMenuButton<String>(
                    tooltip: 'Действия',
                    icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.7)),
                    onSelected: (value) async {
                      if (value == 'edit' && canEditRole) {
                        final ok = await _showEditRoleDialog(
                          context: context,
                          ref: ref,
                          participant: participant,
                          participantsKey: key,
                        );
                        if (ok == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Роль обновлена')),
                          );
                        }
                      } else if (value == 'delete' && canDelete) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Удалить участника?'),
                            content: Text(
                              '${participant.displayName} будет исключён из проекта.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Отмена'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Удалить'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true || !context.mounted) return;
                        try {
                          await ref
                              .read(projectParticipantsControllerProvider(key).notifier)
                              .removeParticipant(participantId: participant.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Участник удалён')),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e is ApiException ? e.message : 'Не удалось удалить',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (canEditRole)
                        const PopupMenuItem(value: 'edit', child: Text('Изменить роль')),
                      if (canDelete)
                        const PopupMenuItem(value: 'delete', child: Text('Удалить')),
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

class _LevelChip extends StatelessWidget {
  final String level;

  const _LevelChip({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        level == 'first' ? 'Уровень 1' : 'Уровень 2',
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

Future<bool?> _showEditRoleDialog({
  required BuildContext context,
  required WidgetRef ref,
  required ProjectParticipant participant,
  required _ParticipantsKey participantsKey,
}) async {
  const allowedRoles = ['PARTNER', 'SUPERVISOR', 'EMPLOYEE'];
  const roleLabels = {
    'PARTNER': 'Партнёр',
    'SUPERVISOR': 'Куратор',
    'EMPLOYEE': 'Сотрудник',
  };

  var selectedRole = allowedRoles.contains(participant.role) ? participant.role : allowedRoles.first;
  bool isSubmitting = false;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Изменить роль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              participant.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Роль в проекте',
                isDense: true,
              ),
              items: allowedRoles
                  .map(
                    (r) => DropdownMenuItem<String>(
                      value: r,
                      child: Text(roleLabels[r] ?? r),
                    ),
                  )
                  .toList(),
              onChanged: isSubmitting
                  ? null
                  : (v) => setState(() => selectedRole = v ?? selectedRole),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    setState(() => isSubmitting = true);
                    try {
                      await ref
                          .read(projectParticipantsControllerProvider(participantsKey).notifier)
                          .updateParticipantRole(
                            participantId: participant.id,
                            role: selectedRole,
                          );
                      if (ctx.mounted) Navigator.of(ctx).pop(true);
                    } catch (e) {
                      setState(() => isSubmitting = false);
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            e is ApiException ? e.message : 'Не удалось обновить роль',
                          ),
                        ),
                      );
                    }
                  },
            child: Text(isSubmitting ? 'Сохранение...' : 'Сохранить'),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────── Empty / Error ────────────────────────────────

class _EmptyBody extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyBody({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.white.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              'Участников пока нет',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте первого участника проекта',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Добавить участника',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
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

// ─────────────────────────── Add Participant Dialog ────────────────────────

Future<bool?> showAddProjectParticipantDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int companyId,
  required List<ProjectParticipant> existingParticipants,
  required Future<void> Function({
    required int counterpartyId,
    required String role,
  }) onAdd,
}) async {
  final existingIds = existingParticipants.map((p) => p.counterpartyId).toSet();

  List<Counterparty> allCounterparties;
  try {
    final repo = ref.read(counterpartiesRepositoryProvider);
    final page = await repo.listCompany(
      companyId: companyId,
      page: 1,
      perPage: 100,
    );
    allCounterparties = page.items
        .where((c) =>
            c.companyRole != 'CUSTOMER' &&
            c.companyRole != 'OWNER' &&
            !existingIds.contains(c.id))
        .toList(growable: false);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить контрагентов: $e')),
      );
    }
    return false;
  }

  if (!context.mounted) return false;

  if (allCounterparties.isEmpty) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Нет доступных контрагентов'),
        content: const Text('Нет доступных контрагентов для добавления'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
    return false;
  }

  const allowedRoles = ['PARTNER', 'SUPERVISOR', 'EMPLOYEE'];
  const roleLabels = {
    'PARTNER': 'Партнёр',
    'SUPERVISOR': 'Куратор',
    'EMPLOYEE': 'Сотрудник',
  };

  Counterparty selected = allCounterparties.first;
  String selectedRole = allowedRoles.first;
  bool isSubmitting = false;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Добавить участника'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Контрагент',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: selected.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: allCounterparties
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(
                          c.pickerDisplayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: isSubmitting
                    ? null
                    : (v) {
                        if (v == null) return;
                        setState(
                          () => selected = allCounterparties.firstWhere((c) => c.id == v),
                        );
                      },
              ),
              const SizedBox(height: 16),
              const Text(
                'Роль в проекте',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: allowedRoles
                    .map(
                      (r) => DropdownMenuItem<String>(
                        value: r,
                        child: Text(roleLabels[r] ?? r),
                      ),
                    )
                    .toList(),
                onChanged:
                    isSubmitting ? null : (v) => setState(() => selectedRole = v ?? selectedRole),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    setState(() => isSubmitting = true);
                    try {
                      await onAdd(counterpartyId: selected.id, role: selectedRole);
                      if (ctx.mounted) Navigator.of(ctx).pop(true);
                    } catch (e) {
                      setState(() => isSubmitting = false);
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            e is ApiException ? e.message : 'Не удалось добавить участника',
                          ),
                        ),
                      );
                    }
                  },
            child: Text(isSubmitting ? 'Добавление...' : 'Добавить'),
          ),
        ],
      ),
    ),
  );
}
