import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../providers.dart';

class ProjectPriceListsScreen extends ConsumerWidget {
  final int companyId;
  final int projectId;
  final String projectName;
  final bool canManageAttachments;

  const ProjectPriceListsScreen({
    super.key,
    required this.companyId,
    required this.projectId,
    required this.projectName,
    required this.canManageAttachments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = (companyId: companyId, projectId: projectId);
    final async = ref.watch(projectPriceListsProvider(key));
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabel(ref, companyId, l10n);

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.projectPriceLists,
      subtitle: projectName,
      floatingActionButton: canManageAttachments
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => _AttachPriceListsPage(
                      companyId: companyId,
                      projectId: projectId,
                    ),
                  ),
                );
                ref.invalidate(projectPriceListsProvider(key));
              },
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.link_rounded, color: Colors.white),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => Center(child: Text('$e', style: AppTextStyles.body.copyWith(color: AppColors.error))),
        data: (rows) {
          if (rows.isEmpty) {
            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async => ref.invalidate(projectPriceListsProvider(key)),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.35,
                    child: AppEmptyState(icon: Icons.request_quote_outlined, title: l10n.priceListsEmpty),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async => ref.invalidate(projectPriceListsProvider(key)),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name, style: AppTextStyles.bodyStrong),
                              Text(
                                '${l10n.priceListCreator}: ${r.creatorDisplayName}',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (canManageAttachments)
                          TextButton(
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n.detachPriceList),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirm)),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await ref.read(priceListsRepositoryProvider).detachFromProject(
                                      companyId: companyId,
                                      projectId: projectId,
                                      priceListId: r.priceListId,
                                    );
                                ref.invalidate(projectPriceListsProvider(key));
                              }
                            },
                            child: Text(l10n.detachPriceList),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AttachPriceListsPage extends ConsumerStatefulWidget {
  final int companyId;
  final int projectId;

  const _AttachPriceListsPage({required this.companyId, required this.projectId});

  @override
  ConsumerState<_AttachPriceListsPage> createState() => _AttachPriceListsPageState();
}

class _AttachPriceListsPageState extends ConsumerState<_AttachPriceListsPage> {
  final Set<int> _sel = {};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = (companyId: widget.companyId, projectId: widget.projectId);
    final async = ref.watch(availableProjectPriceListsProvider(key));
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabel(ref, widget.companyId, l10n);

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.attachPriceLists,
      body: async.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(l10n.priceListsEmpty));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final checked = _sel.contains(p.id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _sel.add(p.id);
                          } else {
                            _sel.remove(p.id);
                          }
                        });
                      },
                      title: Text(p.name),
                      subtitle: Text(p.creatorDisplayName),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _sel.isEmpty
                      ? null
                      : () async {
                          await ref.read(priceListsRepositoryProvider).attachToProject(
                                companyId: widget.companyId,
                                projectId: widget.projectId,
                                priceListIds: _sel.toList(),
                              );
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  child: Text(l10n.attachSelected),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
