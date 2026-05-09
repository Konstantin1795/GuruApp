import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../counterparties/domain/counterparty.dart';
import '../../projects/domain/project.dart';
import '../providers.dart';
import 'company_dashboard_screen.dart';
import 'company_counterparties_screen.dart';
import 'company_operations_placeholder_screen.dart';
import 'company_projects_screen.dart';
import 'transfers_screen.dart';

class CompanyWorkspaceShell extends ConsumerStatefulWidget {
  final int companyId;
  const CompanyWorkspaceShell({super.key, required this.companyId});

  @override
  ConsumerState<CompanyWorkspaceShell> createState() => _CompanyWorkspaceShellState();
}

class _CompanyWorkspaceShellState extends ConsumerState<CompanyWorkspaceShell> {
  int _index = 0;

  Future<void> _quickCreateCounterparty() async {
    final fullNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String role = 'CUSTOMER';
    bool isSubmitting = false;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add counterparty'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppInput(
                  controller: fullNameCtrl,
                  label: 'ФИО',
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                AppInput(
                  controller: emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Роль'),
                  items: [
                    for (final r in kCompanyWorkspaceCounterpartyRoles)
                      DropdownMenuItem<String>(
                        value: r,
                        child: Text(companyWorkspaceCounterpartyRoleLabelRu(r)),
                      ),
                  ],
                  onChanged: isSubmitting ? null : (v) => role = v ?? role,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final fullName = fullNameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      if (fullName.isEmpty) {
                        ScaffoldMessenger.of(ctx)
                            .showSnackBar(const SnackBar(content: Text('Введите ФИО')));
                        return;
                      }
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(ctx)
                            .showSnackBar(const SnackBar(content: Text('Введите email')));
                        return;
                      }
                      setState(() => isSubmitting = true);
                      try {
                        await ref
                            .read(companyCounterpartiesControllerProvider(widget.companyId).notifier)
                            .create(companyRoleCode: role, fullName: fullName, email: email);
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (e) {
                        setState(() => isSubmitting = false);
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(e is ApiException ? e.message : 'Ошибка создания')),
                        );
                      }
                    },
              child: Text(isSubmitting ? 'Creating...' : 'Create'),
            ),
          ],
        ),
      ),
    );

    if (created == true && mounted) {
      setState(() => _index = 2);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Контрагент добавлен')));
    }
  }

  Future<void> _quickCreateProject() async {
    final created = await showCompanyCreateProjectDialog(
      context: context,
      ref: ref,
      companyId: widget.companyId,
      autofocusProjectName: true,
    );
    if (created != true || !mounted) return;
    setState(() => _index = 1);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Проект создан')));
  }

  // ─── Operation type picker ────────────────────────────────────────────────

  Future<void> _showOperationTypePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const Text(
                'Тип операции',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              // Поступление — disabled (next stage)
              _OperationTypeItem(
                icon: Icons.arrow_downward_rounded,
                label: 'Поступление',
                description: 'Будет доступно на следующем этапе',
                enabled: false,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              // Перевод — active
              _OperationTypeItem(
                icon: Icons.swap_horiz,
                label: 'Перевод',
                description: 'Перераспределение средств между участниками',
                enabled: true,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openCreateTransferFlow();
                },
              ),
              const SizedBox(height: 12),
              // Отчёт — disabled (future)
              _OperationTypeItem(
                icon: Icons.receipt_long_outlined,
                label: 'Отчёт',
                description: 'Будет доступно позже',
                enabled: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Picks a project (shows dialog if multiple) then opens CreateTransferScreen.
  Future<void> _openCreateTransferFlow() async {
    // Ensure projects are loaded.
    final projectsState =
        ref.read(companyProjectsControllerProvider(widget.companyId)).valueOrNull;

    if (projectsState == null || projectsState.items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет доступных проектов. Создайте проект сначала.')),
      );
      return;
    }

    Project? selectedProject;

    if (projectsState.items.length == 1) {
      selectedProject = projectsState.items.first;
    } else {
      // Show project picker dialog.
      if (!mounted) return;
      selectedProject = await showDialog<Project>(
        context: context,
        builder: (ctx) => SimpleDialog(
          backgroundColor: const Color(0xFF0B1B2A),
          title: const Text('Выберите проект', style: TextStyle(color: Colors.white)),
          children: projectsState.items
              .map(
                (p) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      p.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    if (selectedProject == null || !mounted) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateTransferScreen(
          companyId: widget.companyId,
          projectId: selectedProject!.id,
          projectName: selectedProject.name,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final companyId = widget.companyId;
    final company = ref.watch(currentCompanyProvider(companyId));
    final companyName = company.valueOrNull?.name ?? 'Company #$companyId';
    final title = switch (_index) {
      0 => companyName,
      1 => 'Projects',
      2 => 'Counterparties',
      3 => 'Операции',
      _ => companyName,
    };
    final subtitle = _index == 0 ? 'Руководитель компании' : null;

    return AppScaffold(
      title: title,
      subtitle: subtitle,
      actions: [
        if (_index == 0)
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('TODO: menu'))),
            icon: const Icon(Icons.menu),
          ),
        IconButton(
          onPressed: () => context.go('/workspaces'),
          icon: const Icon(Icons.apps),
        ),
        if (_index == 0)
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('TODO: more'))),
            icon: const Icon(Icons.more_vert),
          ),
      ],
      body: IndexedStack(
        index: _index,
        children: [
          CompanyDashboardScreen(
            companyId: companyId,
            onOpenProjects: () => setState(() => _index = 1),
            onOpenCounterparties: () => setState(() => _index = 2),
            onQuickCreateProject: _quickCreateProject,
            onQuickCreateCounterparty: _quickCreateCounterparty,
          ),
          CompanyProjectsScreen(companyId: companyId, showCreateButton: true),
          CompanyCounterpartiesScreen(companyId: companyId, showHeader: true),
          const CompanyOperationsPlaceholderScreen(),
        ],
      ),
      bottomNavigationBar: _BottomPillNav(
        activeIndex: _index,
        onSelect: (i) => setState(() => _index = i),
        onOperations: _showOperationTypePicker,
      ),
    );
  }
}

// ─── Bottom navigation ────────────────────────────────────────────────────────

class _BottomPillNav extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOperations;

  const _BottomPillNav({
    required this.activeIndex,
    required this.onSelect,
    required this.onOperations,
  });

  static const _accent = Color(0xFF00D6C9);

  @override
  Widget build(BuildContext context) {
    final selectedHome = activeIndex == 0;

    Widget circle({
      required IconData icon,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: selected ? 1 : 0.85)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF0B1B2A)),
        ),
      );
    }

    Widget pill() {
      return InkWell(
        onTap: onOperations,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _accent, width: 2),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.swap_horiz, color: Color(0xFF0B1B2A)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Операции',
                style: TextStyle(color: Color(0xFF0B1B2A), fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            circle(
              icon: Icons.home_filled,
              selected: selectedHome,
              onTap: () => onSelect(0),
            ),
            const SizedBox(width: 14),
            circle(
              icon: Icons.notifications,
              selected: false,
              onTap: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('TODO: уведомления'))),
            ),
            const Spacer(),
            pill(),
          ],
        ),
      ),
    );
  }
}

// ─── Operation type picker item ───────────────────────────────────────────────

class _OperationTypeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool enabled;
  final VoidCallback onTap;

  const _OperationTypeItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.enabled,
    required this.onTap,
  });

  static const _accent = Color(0xFF00D6C9);

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled ? _accent : Colors.white.withValues(alpha: 0.25);
    final textColor = enabled ? Colors.white : Colors.white.withValues(alpha: 0.35);
    final descColor = enabled
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.25);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.07 : 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? _accent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: TextStyle(color: descColor, fontSize: 12)),
                ],
              ),
            ),
            if (enabled)
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
