import 'dart:math' as math;

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
import '../../../features/auth/presentation/login_screen.dart';
import '../../auth/providers.dart';
import '../domain/personal_company_row.dart';
import '../domain/personal_workspace_project_row.dart';
import 'money_format.dart';
import '../providers.dart';

class _CompanyViewModel {
  final PersonalCompanyRow company;
  final String balanceSum;
  final String spentSum;
  final String debtSum;

  _CompanyViewModel({
    required this.company,
    required this.balanceSum,
    required this.spentSum,
    required this.debtSum,
  });
}

class CustomerCompaniesScreen extends ConsumerStatefulWidget {
  const CustomerCompaniesScreen({super.key});

  @override
  ConsumerState<CustomerCompaniesScreen> createState() => _CustomerCompaniesScreenState();
}

class _CustomerCompaniesScreenState extends ConsumerState<CustomerCompaniesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_CompanyViewModel> _buildModels(
    List<PersonalCompanyRow> companies,
    List<PersonalWorkspaceProjectRow> projects,
    String localeName,
  ) {
    final byCompany = <int, ({double b, double s})>{};
    for (final p in projects) {
      final cur = byCompany[p.companyId] ?? (b: 0.0, s: 0.0);
      final nb = cur.b + parseDecimalMoney(p.wallet.personalBalance);
      final ns = cur.s + parseDecimalMoney(p.wallet.accountableSpent);
      byCompany[p.companyId] = (b: nb, s: ns);
    }

    final out = <_CompanyViewModel>[];
    for (final c in companies) {
      final agg = byCompany[c.id] ?? (b: 0.0, s: 0.0);
      final debt = math.max(0, -agg.b);
      out.add(
        _CompanyViewModel(
          company: c,
          balanceSum: formatMoneyDisplay(agg.b.toStringAsFixed(2), localeName),
          spentSum: formatMoneyDisplay(agg.s.toStringAsFixed(2), localeName),
          debtSum: formatMoneyDisplay(debt.toStringAsFixed(2), localeName),
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final async = ref.watch(customerWorkspaceDataProvider);
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (userName.isNotEmpty)
                  Expanded(
                    child: Text(
                      userName,
                      style: AppTextStyles.bodyStrong,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                Text(
                  l10n.roleCustomer,
                  style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(l10n.customerCompaniesTitle, style: AppTextStyles.screenTitle),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
        actions: const [LocaleSwitchButton()],
      ),
      body: async.when(
        data: (data) {
          // Until company/project status is owner-managed in the UI, show all companies.
          var models = _buildModels(data.companies, data.projects, localeName);
          final q = _search.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            models = models.where((m) => m.company.name.toLowerCase().contains(q)).toList();
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
                child: models.isEmpty
                    ? AppEmptyState(
                        icon: Icons.apartment_rounded,
                        title: l10n.customerNoData,
                        description: l10n.customerWorkspaceSubtitle,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                        itemCount: models.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final m = models[i];
                          final c = m.company;
                          final letter = c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';
                          final hue = (c.name.hashCode & 0x7FFFFFFF) % 360;
                          final dot = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.48).toColor();

                          return AppCard(
                            onTap: () => context.push('/customer/companies/${c.id}/projects', extra: c.name),
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
                                      child: Text(
                                        c.name,
                                        style: AppTextStyles.cardTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                                      child: Text(
                                        '${c.projectsCount}',
                                        style: AppTextStyles.screenTitle.copyWith(fontSize: 24),
                                      ),
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
                                      _kv(l10n.customerBalancePersonal, m.balanceSum),
                                      const Divider(height: AppSpacing.lg, color: AppColors.border),
                                      _kv(l10n.customerSpentAccumulated, m.spentSum),
                                      const Divider(height: AppSpacing.lg, color: AppColors.border),
                                      _kv(l10n.customerDebt, m.debtSum),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: AppLoader()),
        error: (e, st) => Center(child: Text(l10n.customerErrorLoad, style: const TextStyle(color: AppColors.error))),
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
