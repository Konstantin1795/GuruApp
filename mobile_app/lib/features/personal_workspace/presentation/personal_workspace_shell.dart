import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';

class PersonalWorkspaceShell extends StatelessWidget {
  const PersonalWorkspaceShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Personal workspace',
      actions: [
        IconButton(
          onPressed: () => context.go('/workspaces'),
          icon: const Icon(Icons.apps),
        ),
      ],
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Workspace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Text('Shell screen (placeholder).'),
            SizedBox(height: 12),
            Text('TODO later: companies/projects lists, income chart, notifications.'),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
        ],
      ),
    );
  }
}

