import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/project_expense_item.dart';
import '../providers.dart';

typedef ExpenseRecipientsArgs = ({
  int companyId,
  int projectId,
  String search,
});

/// Bottom sheet: один список контрагентов компании, поиск, множественный выбор (ТЗ-10A MVP).
Future<List<ExpenseItemRecipientOption>?> showExpenseItemRecipientPicker({
  required BuildContext context,
  required int companyId,
  required int projectId,
  Set<int>? initiallySelected,
}) {
  return showModalBottomSheet<List<ExpenseItemRecipientOption>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ExpenseItemRecipientPickerBody(
      companyId: companyId,
      projectId: projectId,
      initiallySelected: initiallySelected ?? {},
    ),
  );
}

class _ExpenseItemRecipientPickerBody extends ConsumerStatefulWidget {
  final int companyId;
  final int projectId;
  final Set<int> initiallySelected;

  const _ExpenseItemRecipientPickerBody({
    required this.companyId,
    required this.projectId,
    required this.initiallySelected,
  });

  @override
  ConsumerState<_ExpenseItemRecipientPickerBody> createState() => _ExpenseItemRecipientPickerBodyState();
}

class _ExpenseItemRecipientPickerBodyState extends ConsumerState<_ExpenseItemRecipientPickerBody> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late Set<int> _selected;
  final Map<int, String> _labels = {};

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initiallySelected};
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  ExpenseRecipientsArgs get _args => (
        companyId: widget.companyId,
        projectId: widget.projectId,
        search: _searchQuery,
      );

  String _nameForId(int id, List<ExpenseItemRecipientOption> loaded) {
    final fromMap = _labels[id];
    if (fromMap != null && fromMap.isNotEmpty) return fromMap;
    for (final e in loaded) {
      if (e.id == id) return e.counterpartyName;
    }
    return '#$id';
  }

  void _confirm(List<ExpenseItemRecipientOption> loaded) {
    final out = <ExpenseItemRecipientOption>[];
    for (final id in _selected) {
      out.add(ExpenseItemRecipientOption(id: id, counterpartyName: _nameForId(id, loaded)));
    }
    Navigator.of(context).pop(out);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(projectExpenseItemRecipientsProvider(_args));

    final pad = MediaQuery.paddingOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: pad.bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.recipients, style: AppTextStyles.cardTitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.companyCounterpartiesTab,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: l10n.customerSearchHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () {
                      setState(() => _searchQuery = _searchCtrl.text.trim());
                    },
                  ),
                ),
                onSubmitted: (_) {
                  setState(() => _searchQuery = _searchCtrl.text.trim());
                },
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text('$e', style: AppTextStyles.body.copyWith(color: AppColors.error)),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.customerNoData,
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final r = list[i];
                      final checked = _selected.contains(r.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(r.id);
                              _labels[r.id] = r.counterpartyName;
                            } else {
                              _selected.remove(r.id);
                            }
                          });
                        },
                        title: Text(r.counterpartyName, style: AppTextStyles.bodyStrong),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: async.maybeWhen(
                data: (list) => AppButton(
                  label: l10n.confirm,
                  onPressed: () => _confirm(list),
                ),
                orElse: () => AppButton(
                  label: l10n.confirm,
                  loading: true,
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
