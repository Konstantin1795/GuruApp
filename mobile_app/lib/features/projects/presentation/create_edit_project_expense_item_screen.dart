import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../domain/expense_percent_validation.dart';
import '../providers.dart';
import 'expense_item_recipient_picker_sheet.dart';

class _ShareEdit {
  _ShareEdit({
    required this.counterpartyId,
    required this.name,
    required String percent,
  }) : percent = TextEditingController(text: percent);

  final int counterpartyId;
  final String name;
  final TextEditingController percent;
}

/// Создание / просмотр / редактирование статьи расходов (ТЗ-10A).
class CreateEditProjectExpenseItemScreen extends ConsumerStatefulWidget {
  final int companyId;
  final int projectId;
  final int? expenseItemId;
  final bool canManage;

  const CreateEditProjectExpenseItemScreen({
    super.key,
    required this.companyId,
    required this.projectId,
    required this.expenseItemId,
    required this.canManage,
  });

  @override
  ConsumerState<CreateEditProjectExpenseItemScreen> createState() => _CreateEditProjectExpenseItemScreenState();
}

class _CreateEditProjectExpenseItemScreenState extends ConsumerState<CreateEditProjectExpenseItemScreen> {
  final _nameCtrl = TextEditingController();
  final _markupPercentCtrl = TextEditingController();
  bool _markupEnabled = false;
  List<_ShareEdit> _profit = [];
  List<_ShareEdit> _markup = [];
  bool _loadingBootstrap = false;
  String? _bootstrapError;
  bool _saving = false;

  bool get _isEdit => widget.expenseItemId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadingBootstrap = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
    }
  }

  Future<void> _loadDetail() async {
    try {
      final id = widget.expenseItemId!;
      final d = await ref.read(projectExpenseItemsRepositoryProvider).getDetail(
            companyId: widget.companyId,
            projectId: widget.projectId,
            expenseItemId: id,
          );
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = d.name;
        _markupEnabled = d.markupEnabled;
        _markupPercentCtrl.text = d.markupPercent ?? '';
        _profit = d.profitShares
            .map(
              (s) => _ShareEdit(
                counterpartyId: s.counterpartyId,
                name: s.counterpartyName,
                percent: s.percent,
              ),
            )
            .toList();
        _markup = d.markupShares
            .map(
              (s) => _ShareEdit(
                counterpartyId: s.counterpartyId,
                name: s.counterpartyName,
                percent: s.percent,
              ),
            )
            .toList();
        _loadingBootstrap = false;
        _bootstrapError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingBootstrap = false;
        _bootstrapError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _markupPercentCtrl.dispose();
    for (final r in _profit) {
      r.percent.dispose();
    }
    for (final r in _markup) {
      r.percent.dispose();
    }
    super.dispose();
  }

  void _disposeShareList(List<_ShareEdit> list) {
    for (final r in list) {
      r.percent.dispose();
    }
  }

  Future<void> _pickProfitRecipients() async {
    final picked = await showExpenseItemRecipientPicker(
      context: context,
      companyId: widget.companyId,
      projectId: widget.projectId,
      initiallySelected: _profit.map((e) => e.counterpartyId).toSet(),
    );
    if (picked == null || !mounted) return;

    final existing = {for (final r in _profit) r.counterpartyId: r};
    final next = <_ShareEdit>[];
    for (final p in picked) {
      final prev = existing[p.id];
      if (prev != null) {
        next.add(prev);
      } else {
        next.add(_ShareEdit(counterpartyId: p.id, name: p.counterpartyName, percent: ''));
      }
    }
    final removed = _profit.where((r) => !next.any((n) => n.counterpartyId == r.counterpartyId)).toList();
    _disposeShareList(removed);
    setState(() => _profit = next);
  }

  Future<void> _pickMarkupRecipients() async {
    final picked = await showExpenseItemRecipientPicker(
      context: context,
      companyId: widget.companyId,
      projectId: widget.projectId,
      initiallySelected: _markup.map((e) => e.counterpartyId).toSet(),
    );
    if (picked == null || !mounted) return;

    final existing = {for (final r in _markup) r.counterpartyId: r};
    final next = <_ShareEdit>[];
    for (final p in picked) {
      final prev = existing[p.id];
      if (prev != null) {
        next.add(prev);
      } else {
        next.add(_ShareEdit(counterpartyId: p.id, name: p.counterpartyName, percent: ''));
      }
    }
    final removed = _markup.where((r) => !next.any((n) => n.counterpartyId == r.counterpartyId)).toList();
    _disposeShareList(removed);
    setState(() => _markup = next);
  }

  void _removeProfitAt(int i) {
    final r = _profit.removeAt(i);
    r.percent.dispose();
    setState(() {});
  }

  void _removeMarkupAt(int i) {
    final r = _markup.removeAt(i);
    r.percent.dispose();
    setState(() {});
  }

  String? _validateBeforeSave(BuildContext context) {
    final l10n = context.l10n;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return l10n.expenseItemNameRequired;

    if (_profit.isEmpty) return l10n.profitRecipientsRequired;

    final profitPercents = _profit.map((r) => r.percent.text.trim()).toList();
    if (!expensePercentsSumToFull(profitPercents)) {
      return l10n.profitSharesMustEqualHundred;
    }
    for (final p in profitPercents) {
      if (expensePercentHundredths(p) == null) return l10n.percentFormatHint;
    }

    if (_markupEnabled) {
      final mp = _markupPercentCtrl.text.trim();
      if (expensePercentHundredths(mp) == null) return l10n.markupPercentInvalid;

      if (_markup.isEmpty) return l10n.markupRecipientsRequired;

      final mPercents = _markup.map((r) => r.percent.text.trim()).toList();
      if (!expensePercentsSumToFull(mPercents)) {
        return l10n.markupSharesMustEqualHundred;
      }
      for (final p in mPercents) {
        if (expensePercentHundredths(p) == null) return l10n.percentFormatHint;
      }
    }

    return null;
  }

  Future<void> _save() async {
    final err = _validateBeforeSave(context);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(projectExpenseItemsRepositoryProvider);
    final keyList = (companyId: widget.companyId, projectId: widget.projectId);

    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'markup_enabled': _markupEnabled,
      'profit_shares': _profit
          .map(
            (r) => {
              'counterparty_id': r.counterpartyId,
              'percent': r.percent.text.trim(),
            },
          )
          .toList(),
      if (_markupEnabled) ...{
        'markup_percent': _markupPercentCtrl.text.trim(),
        'markup_shares': _markup
            .map(
              (r) => {
                'counterparty_id': r.counterpartyId,
                'percent': r.percent.text.trim(),
              },
            )
            .toList(),
      },
    };

    try {
      if (_isEdit) {
        await repo.update(
          companyId: widget.companyId,
          projectId: widget.projectId,
          expenseItemId: widget.expenseItemId!,
          body: body,
        );
      } else {
        await repo.create(
          companyId: widget.companyId,
          projectId: widget.projectId,
          body: body,
        );
      }
      if (!mounted) return;
      ref.invalidate(projectExpenseItemsProvider(keyList));
      if (_isEdit) {
        ref.invalidate(projectExpenseItemDetailProvider((
          companyId: widget.companyId,
          projectId: widget.projectId,
          expenseItemId: widget.expenseItemId!,
        )));
      }
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteExpenseItem),
        content: Text(l10n.deleteExpenseItemConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    final repo = ref.read(projectExpenseItemsRepositoryProvider);
    final keyList = (companyId: widget.companyId, projectId: widget.projectId);
    try {
      await repo.delete(
        companyId: widget.companyId,
        projectId: widget.projectId,
        expenseItemId: widget.expenseItemId!,
      );
      if (!mounted) return;
      ref.invalidate(projectExpenseItemsProvider(keyList));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.expenseItemDeleted)));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabel(ref, widget.companyId, l10n);
    final readOnly = !widget.canManage;

    if (_loadingBootstrap) {
      return AppScaffold(
        headerUserName: userName.isEmpty ? null : userName,
        headerRoleLabel: roleLabel,
        title: _isEdit ? l10n.editExpenseItem : l10n.createExpenseItem,
        body: const Center(child: AppLoader()),
      );
    }

    if (_bootstrapError != null) {
      return AppScaffold(
        headerUserName: userName.isEmpty ? null : userName,
        headerRoleLabel: roleLabel,
        title: l10n.editExpenseItem,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(_bootstrapError!, style: AppTextStyles.body.copyWith(color: AppColors.error)),
          ),
        ),
      );
    }

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: _isEdit ? l10n.editExpenseItem : l10n.createExpenseItem,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.x3l * 2),
        children: [
              AppInput(
                controller: _nameCtrl,
                label: l10n.expenseItemName,
                enabled: !readOnly,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.profitShares.toUpperCase(), style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              if (!readOnly)
                AppButton(
                  label: l10n.addProfitRecipient,
                  outlined: true,
                  icon: Icons.person_add_outlined,
                  onPressed: _pickProfitRecipients,
                ),
              const SizedBox(height: AppSpacing.sm),
              ...List.generate(_profit.length, (i) => _shareTile(context, _profit[i], () => _removeProfitAt(i), readOnly)),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.markupOnExpenseItem, style: AppTextStyles.bodyStrong),
                value: _markupEnabled,
                activeThumbColor: AppColors.accent,
                onChanged: readOnly
                    ? null
                    : (v) {
                        setState(() {
                          _markupEnabled = v;
                          if (!v) {
                            _disposeShareList(_markup);
                            _markup = [];
                          }
                        });
                      },
              ),
              if (_markupEnabled) ...[
                AppInput(
                  controller: _markupPercentCtrl,
                  label: l10n.markupPercent,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !readOnly,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.markupShares.toUpperCase(), style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                if (!readOnly)
                  AppButton(
                    label: l10n.addMarkupRecipient,
                    outlined: true,
                    icon: Icons.person_add_outlined,
                    onPressed: _pickMarkupRecipients,
                  ),
                const SizedBox(height: AppSpacing.sm),
                ...List.generate(_markup.length, (i) => _shareTile(context, _markup[i], () => _removeMarkupAt(i), readOnly)),
              ],
              if (!readOnly) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: l10n.save,
                  loading: _saving,
                  onPressed: _saving ? () {} : _save,
                ),
                if (_isEdit) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: l10n.deleteExpenseItem,
                    outlined: true,
                    onPressed: _saving ? () {} : _confirmDelete,
                  ),
                ],
              ],
        ],
      ),
    );
  }

  Widget _shareTile(BuildContext context, _ShareEdit row, VoidCallback onRemove, bool readOnly) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(row.name, style: AppTextStyles.body),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: readOnly
                ? Text('${row.percent.text}%', style: AppTextStyles.bodyStrong)
                : TextField(
                    controller: row.percent,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '%',
                      border: const OutlineInputBorder(),
                      hintText: l10n.percentHintShort,
                    ),
                  ),
          ),
          if (!readOnly)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, color: AppColors.error),
            ),
        ],
      ),
    );
  }
}
