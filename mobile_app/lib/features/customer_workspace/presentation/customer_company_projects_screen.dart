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
import '../providers.dart';
import 'money_format.dart';

class CustomerCompanyProjectsScreen extends ConsumerStatefulWidget {
  final int companyId;
  final String? companyName;

  const CustomerCompanyProjectsScreen({
    super.key,
    required this.companyId,
    this.companyName,
  });

  @override
  ConsumerState<CustomerCompanyProjectsScreen> createState() => _CustomerCompanyProjectsScreenState();
}

class _CustomerCompanyProjectsScreenState extends ConsumerState<CustomerCompanyProjectsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String? _resolveHeaderName(CustomerWorkspaceData data) {
    if (widget.companyName != null && widget.companyName!.isNotEmpty) {
      return widget.companyName;
    }
    for (final p in data.projects) {
      if (p.companyId == widget.companyId) return p.companyName;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final async = ref.watch(customerWorkspaceDataProvider);

    Future<void> reload() async {
      ref.invalidate(customerWorkspaceDataProvider);
      await ref.read(customerWorkspaceDataProvider.future);
    }

    final headerName = async.maybeWhen(
      data: _resolveHeaderName,
      orElse: () => widget.companyName,
    );

    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
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
            const SizedBox(height: 6),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                  child: Text(
                    (headerName != null && headerName.isNotEmpty) ? headerName[0].toUpperCase() : '?',
                    style: AppTextStyles.bodyStrong.copyWith(color: AppColors.accent),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    headerName ?? l10n.customerProjectsTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: const [LocaleSwitchButton()],
      ),
      body: async.when(
        data: (data) {
          final titleName = _resolveHeaderName(data);

          // Until project lifecycle status is managed in the app, treat all projects as visible
          // (do not filter by is_active).
          var list = data.projects.where((p) => p.companyId == widget.companyId).toList();
          final q = _search.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            list = list.where((p) => p.projectName.toLowerCase().contains(q)).toList();
          }

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
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
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                    child: Text(
                      l10n.customerProjectsTitle.toUpperCase(),
                      style: AppTextStyles.sectionTitle.copyWith(color: AppColors.accent),
                    ),
                  ),
                ),
                if (list.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.folder_open_rounded,
                      title: l10n.customerNoData,
                      description: l10n.customerWorkspaceSubtitle,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final row = list[i];
                        final bal = parseDecimalMoney(row.wallet.personalBalance);
                        final isNeg = bal < 0;
                        final badge = formatMoneyDisplay(row.wallet.personalBalance, localeName);
                        return AppCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          radius: AppRadii.xxl,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      row.projectName,
                                      style: AppTextStyles.screenTitle.copyWith(fontSize: 20, height: 1.25),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(AppRadii.pill),
                                      border: Border.all(
                                        color: isNeg ? AppColors.error.withValues(alpha: 0.5) : AppColors.accentBorder,
                                      ),
                                    ),
                                    child: Text(
                                      isNeg ? '− $badge' : badge,
                                      style: AppTextStyles.bodyStrong.copyWith(
                                        color: isNeg ? AppColors.error : AppColors.accent,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (titleName != null && titleName.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  titleName,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  const Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.projectProgress(row.progressPercent),
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: AppLoader()),
        error: (e, st) => Center(child: Text(l10n.customerErrorLoad, style: const TextStyle(color: AppColors.error))),
      ),
    );
  }
}
