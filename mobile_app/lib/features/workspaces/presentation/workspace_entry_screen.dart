import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../providers.dart';
import '../domain/workspaces.dart';
import '../../auth/presentation/auth_state.dart';

final workspacesProvider = FutureProvider<Workspaces>((ref) async {
  final repo = ref.read(workspacesRepositoryProvider);
  return repo.fetch();
});

class WorkspaceEntryScreen extends ConsumerWidget {
  const WorkspaceEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workspacesProvider);

    return AppScaffold(
      title: 'Workspaces',
      actions: [
        IconButton(
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      body: ws.when(
        data: (data) => _Body(data: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(e is ApiException ? e.message : 'Failed to load workspaces.'),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Workspaces data;
  const _Body({required this.data});

  @override
  Widget build(BuildContext context) {
    final companyWs = data.companyWorkspaces;
    final personal = data.personalWorkspace;

    final hasAny = companyWs.isNotEmpty || personal.available;

    if (!hasAny) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No workspaces available yet.'),
              const SizedBox(height: 12),
              AppButton(
                label: 'Create company',
                onPressed: () => context.go('/create-company'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFC3FF40),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Choose a workspace', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (companyWs.isNotEmpty) ...[
          const Text('Company workspace', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...companyWs.map(
            (c) => AppCard(
              onTap: () => context.go('/company/${c.companyId}'),
              child: Row(
                children: [
                  const Icon(Icons.apartment_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.companyName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(c.role, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (personal.available) ...[
          const Text('Personal workspace', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AppCard(
            onTap: () => context.go('/personal'),
            child: Row(
              children: [
                const Icon(Icons.person_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Open personal workspace',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        'Roles: ${personal.roles.join(', ')}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

