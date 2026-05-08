import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import 'company_counterparties_screen.dart';
import 'company_projects_screen.dart';

class CompanyWorkspaceShell extends StatefulWidget {
  final int companyId;
  const CompanyWorkspaceShell({super.key, required this.companyId});

  @override
  State<CompanyWorkspaceShell> createState() => _CompanyWorkspaceShellState();
}

class _CompanyWorkspaceShellState extends State<CompanyWorkspaceShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final companyId = widget.companyId;
    final title = switch (_index) {
      0 => 'Projects',
      1 => 'Counterparties',
      _ => 'Company #$companyId',
    };

    return AppScaffold(
      title: title,
      actions: [
        IconButton(
          onPressed: () => context.go('/workspaces'),
          icon: const Icon(Icons.apps),
        ),
      ],
      body: IndexedStack(
        index: _index,
        children: [
          CompanyProjectsScreen(companyId: companyId),
          CompanyCounterpartiesScreen(companyId: companyId),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.work_outline), label: 'Projects'),
          NavigationDestination(icon: Icon(Icons.group_outlined), label: 'People'),
        ],
      ),
    );
  }
}

