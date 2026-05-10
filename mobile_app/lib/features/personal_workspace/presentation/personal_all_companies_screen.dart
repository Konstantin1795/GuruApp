import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loader.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers.dart';
import '../providers.dart';
import 'performer_company_vms.dart';

/// Full company list for the performer (supplier / contractor / employee) workspace.
class PersonalAllCompaniesScreen extends ConsumerStatefulWidget {
  const PersonalAllCompaniesScreen({super.key});

  @override
  ConsumerState<PersonalAllCompaniesScreen> createState() => _PersonalAllCompaniesScreenState();
}

class _PersonalAllCompaniesScreenState extends ConsumerState<PersonalAllCompaniesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final async = ref.watch(performerWorkspaceDataProvider);
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: userName.isEmpty
            ? Text(l10n.customerCompaniesTitle)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: AppTextStyles.bodyStrong,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l10n.customerCompaniesTitle,
                    style: AppTextStyles.screenTitle,
                  ),
                ],
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: const [LocaleSwitchButton()],
      ),
      body: async.when(
        data: (data) {
          var vms = buildPerformerCompanyVms(data.companies, data.projects, l10n, localeName);
          final q = _search.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            vms = vms.where((m) => m.company.name.toLowerCase().contains(q)).toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: l10n.customerSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: vms.isEmpty
                    ? AppEmptyState(
                        icon: Icons.apartment_rounded,
                        title: l10n.personalWorkspaceEmpty,
                        description: l10n.personalWorkspacePlaceholder,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                        itemCount: vms.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final m = vms[i];
                          return _ListCompanyTile(model: m);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: AppLoader()),
        error: (e, st) => Center(
          child: Text(l10n.personalWorkspaceLoadError, style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _ListCompanyTile extends StatelessWidget {
  final PerformerCompanyVm model;

  const _ListCompanyTile({required this.model});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = model.company;
    final letter = c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';
    final hue = (c.name.hashCode & 0x7FFFFFFF) % 360;
    final dot = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.48).toColor();

    return AppCard(
      onTap: () => context.go('/company/${c.id}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppRadii.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: dot,
                foregroundColor: Colors.white,
                child: Text(letter, style: AppTextStyles.bodyStrong),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(c.name, style: AppTextStyles.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text('${c.projectsCount}', style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _kv(l10n.personalRoleInCompany, model.roleLabel),
                const Divider(height: AppSpacing.lg, color: AppColors.border),
                _kv(l10n.customerBalancePersonal, model.balance),
                const Divider(height: AppSpacing.lg, color: AppColors.border),
                _kv(l10n.walletReceived, model.received),
                const Divider(height: AppSpacing.lg, color: AppColors.border),
                _kv(l10n.walletEarned, model.earned),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Expanded(child: Text(k, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary))),
        Text(v, style: AppTextStyles.bodyStrong),
      ],
    );
  }
}
