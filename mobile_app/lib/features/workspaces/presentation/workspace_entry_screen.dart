import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/workspaces.dart';
import '../providers.dart';

class WorkspaceEntryScreen extends ConsumerWidget {
  const WorkspaceEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workspacesProvider);
    final l10n = context.l10n;
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';

    return AppScaffold(
      title: l10n.workspacesTitle,
      headerUserName: userName.isEmpty ? null : userName,
      actions: [
        IconButton(
          tooltip: l10n.logout,
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      body: ws.when(
        data: (data) => _Body(data: data),
        loading: () => const AppLoader(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(e is ApiException ? e.message : l10n.workspacesErrorLoad),
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
    final l10n = context.l10n;
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
              Text(l10n.workspacesEmpty),
              const SizedBox(height: 12),
              AppButton(
                label: l10n.createCompanyTitle,
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
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.workspaceChoose,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: l10n.createCompanyTitle,
          onPressed: () => context.go('/create-company'),
        ),
        const SizedBox(height: 16),
        if (companyWs.isNotEmpty) ...[
          Text(
            l10n.workspaceCompany,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...companyWs.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                onTap: () => context.go('/company/${c.companyId}'),
                child: Row(
                  children: [
                    const Icon(Icons.apartment_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.companyName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.role,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (personal.available) ...[
          Text(
            l10n.workspacePersonal,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (personal.roles.contains('CUSTOMER')) ...[
            AppCard(
              onTap: () => context.go('/customer'),
              child: Row(
                children: [
                  const Icon(Icons.handshake_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.openCustomerWorkspace,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.customerWorkspaceSubtitle,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (personal.roles.any((r) => r == 'EMPLOYEE' || r == 'CONTRACTOR' || r == 'SUPPLIER')) ...[
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
                        Text(
                          l10n.openPersonal,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.personalRoles(personal.roles.join(', ')),
                          style: TextStyle(color: AppColors.textSecondary),
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
      ],
    );
  }
}
