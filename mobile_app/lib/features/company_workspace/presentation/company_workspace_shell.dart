import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/presentation/login_screen.dart' show LocaleSwitchButton;
import '../../auth/providers.dart';
import '../../counterparties/domain/counterparty.dart';
import '../../projects/domain/project.dart';
import '../../workspaces/providers.dart';
import '../providers.dart';
import 'company_counterparties_screen.dart' show CompanyCounterpartiesScreen, companyCounterpartiesControllerProvider;
import 'company_dashboard_screen.dart';
import 'company_operations_placeholder_screen.dart';
import 'company_projects_screen.dart';
import 'company_workspace_identity.dart';
import '../../operations/data/transfers_api.dart';
import '../../operations/providers.dart';
import 'transfers_screen.dart' show CreateTransferScreen;

class CompanyWorkspaceShell extends ConsumerStatefulWidget {
  final int companyId;
  const CompanyWorkspaceShell({super.key, required this.companyId});

  @override
  ConsumerState<CompanyWorkspaceShell> createState() => _CompanyWorkspaceShellState();
}

class _CompanyWorkspaceShellState extends ConsumerState<CompanyWorkspaceShell> {
  int _index = 0;

  Future<void> _quickCreateCounterparty() async {
    final l10n = context.l10n;
    final fullNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String role = 'CUSTOMER';
    bool isSubmitting = false;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.addCounterparty),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppInput(
                  controller: fullNameCtrl,
                  label: l10n.counterpartyFullName,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                AppInput(
                  controller: emailCtrl,
                  label: l10n.counterpartyEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: InputDecoration(labelText: l10n.counterpartyRole),
                  items: [
                    for (final r in kCompanyWorkspaceCounterpartyRoles)
                      DropdownMenuItem<String>(
                        value: r,
                        child: Text(_localizeRole(r, l10n)),
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
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final fullName = fullNameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      if (fullName.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(l10n.counterpartyEnterName)),
                        );
                        return;
                      }
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(l10n.counterpartyEnterEmail)),
                        );
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
                          SnackBar(
                            content: Text(
                              e is ApiException ? e.message : l10n.counterpartyErrorCreate,
                            ),
                          ),
                        );
                      }
                    },
              child: Text(isSubmitting ? '...' : l10n.create),
            ),
          ],
        ),
      ),
    );

    if (created == true && mounted) {
      setState(() => _index = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.counterpartyAdded)),
      );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.projectCreated)),
    );
  }

  // ─── Operation type picker ────────────────────────────────────────────────

  Future<void> _showOperationTypePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final l10n = ctx.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  l10n.operationTypeTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _OperationTypeItem(
                  icon: Icons.arrow_downward_rounded,
                  label: l10n.operationIncome,
                  description: l10n.operationIncomeSoon,
                  enabled: false,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _OperationTypeItem(
                  icon: Icons.swap_horiz,
                  label: l10n.operationTransfer,
                  description: l10n.operationTransferDescription,
                  enabled: true,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openCreateTransferFlow();
                  },
                ),
                const SizedBox(height: 12),
                _OperationTypeItem(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.operationReport,
                  description: l10n.operationReportSoon,
                  enabled: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreateTransferFlow() async {
    final l10n = context.l10n;
    final projectsState =
        ref.read(companyProjectsControllerProvider(widget.companyId)).valueOrNull;

    if (projectsState == null || projectsState.items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.noProjects)));
      return;
    }

    Project? selectedProject;

    if (projectsState.items.length == 1) {
      selectedProject = projectsState.items.first;
    } else {
      if (!mounted) return;
      selectedProject = await showDialog<Project>(
        context: context,
        builder: (ctx) => SimpleDialog(
          backgroundColor: const Color(0xFF0B1B2A),
          title: Text(
            ctx.l10n.selectProject,
            style: const TextStyle(color: Colors.white),
          ),
          children: projectsState.items
              .map(
                (p) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    if (selectedProject == null || !mounted) return;
    final project = selectedProject;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateTransferScreen(
          companyId: widget.companyId,
          projectId: project.id,
          projectName: project.name,
        ),
      ),
    );

    if (created == true && mounted) {
      setState(() => _index = 3);
      ref.invalidate(
        transferPendingActionCountProvider(
          (scope: TransferApiScope.company, companyId: widget.companyId),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.transferCreated)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final companyId = widget.companyId;
    final workspacesData = ref.watch(workspacesProvider).valueOrNull;
    final wsEntry = companyWorkspaceEntry(workspacesData, companyId);
    final company = ref.watch(currentCompanyProvider(companyId));

    final nameFromApi = company.valueOrNull?.name.trim();
    final nameFromWs = wsEntry?.companyName.trim();
    final companyName = (nameFromApi != null && nameFromApi.isNotEmpty)
        ? nameFromApi
        : (nameFromWs != null && nameFromWs.isNotEmpty)
            ? nameFromWs
            : l10n.companyWorkspaceFallbackName(companyId);

    final headerRole = companyWorkspaceHeaderRoleLabel(ref, companyId, l10n);
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: headerRole,
      title: companyName,
      actions: [
        if (_index == 0) const LocaleSwitchButton(),
        IconButton(
          onPressed: () => context.go('/workspaces'),
          icon: const Icon(Icons.apps),
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

  static const _accent = AppColors.accent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 1 : 0.85),
            ),
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
              Text(
                l10n.operationsTitle,
                style: const TextStyle(
                  color: Color(0xFF0B1B2A),
                  fontWeight: FontWeight.w800,
                ),
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
                  .showSnackBar(SnackBar(content: Text(l10n.notificationsComingSoon))),
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

  static const _accent = AppColors.accent;

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled ? _accent : Colors.white.withValues(alpha: 0.25);
    final textColor = enabled ? Colors.white : Colors.white.withValues(alpha: 0.35);
    final descColor =
        enabled ? Colors.white.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.25);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.07 : 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? _accent.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.07),
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
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(description,
                      style: TextStyle(color: descColor, fontSize: 12)),
                ],
              ),
            ),
            if (enabled)
              Icon(Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

String _localizeRole(String role, AppLocalizations l10n) => switch (role) {
      'OWNER'      => l10n.roleOwner,
      'PARTNER'    => l10n.rolePartner,
      'EMPLOYEE'   => l10n.roleEmployee,
      'CONTRACTOR' => l10n.roleContractor,
      'SUPPLIER'   => l10n.roleSupplier,
      'CUSTOMER'   => l10n.roleCustomer,
      _            => role,
    };
