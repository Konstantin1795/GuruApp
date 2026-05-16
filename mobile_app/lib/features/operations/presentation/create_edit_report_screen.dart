import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../../projects/domain/project_expense_item.dart';
import '../../projects/providers.dart';
import '../domain/report_line_data.dart';
import '../providers.dart';
import 'report_positions_editor_screen.dart';

/// Создание отчёта (company-workspace). Компактный экран + отдельный редактор позиций.
class CreateEditReportScreen extends ConsumerStatefulWidget {
  final int companyId;
  final int projectId;
  final String projectName;

  const CreateEditReportScreen({
    super.key,
    required this.companyId,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<CreateEditReportScreen> createState() => _CreateEditReportScreenState();
}

class _CreateEditReportScreenState extends ConsumerState<CreateEditReportScreen> {
  final _commentCtrl = TextEditingController();
  final _manualRecipientCtrl = TextEditingController(text: '0');
  final _manualCustomerCtrl = TextEditingController(text: '0');

  int? _expenseItemId;
  int? _recipientCounterpartyId;
  DateTime _operationDate = DateTime.now();

  List<ProjectExpenseItemListRow> _expenseItems = [];
  List<ExpenseItemRecipientOption> _recipients = [];
  List<ReportLineData> _lines = [];
  bool _loadingMeta = true;
  bool _submitting = false;
  String? _metaError;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _manualRecipientCtrl.dispose();
    _manualCustomerCtrl.dispose();
    super.dispose();
  }

  ProjectExpenseItemListRow? get _selectedExpense {
    final id = _expenseItemId;
    if (id == null) return null;
    for (final e in _expenseItems) {
      if (e.id == id) return e;
    }
    return null;
  }

  bool get _hasLines => _lines.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loadingMeta = true;
      _metaError = null;
    });
    try {
      final exp = await ref.read(projectExpenseItemsRepositoryProvider).list(
            companyId: widget.companyId,
            projectId: widget.projectId,
          );
      final rec = await ref.read(projectExpenseItemsRepositoryProvider).recipients(
            companyId: widget.companyId,
            projectId: widget.projectId,
            search: null,
          );
      if (!mounted) return;
      setState(() {
        _expenseItems = exp.where((e) => e.isActive).toList();
        _recipients = rec;
        _expenseItemId = _expenseItems.isNotEmpty ? _expenseItems.first.id : null;
        _recipientCounterpartyId = _recipients.isNotEmpty ? _recipients.first.id : null;
        _loadingMeta = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _metaError = e is ApiException ? e.message : '_generic';
        _loadingMeta = false;
      });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _operationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _operationDate = picked);
  }

  Future<void> _openPositionsEditor() async {
    final result = await Navigator.of(context).push<List<ReportLineData>>(
      MaterialPageRoute<List<ReportLineData>>(
        fullscreenDialog: true,
        builder: (_) => ReportPositionsEditorScreen(
          companyId: widget.companyId,
          projectId: widget.projectId,
          projectName: widget.projectName,
          initialLines: List<ReportLineData>.from(_lines),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _lines = result);
    }
  }

  ({double recipient, double customerBase, double markup, double customerTotal, double profit}) _previewTotals() {
    if (_hasLines) {
      double rec = 0;
      double cbase = 0;
      for (final l in _lines) {
        rec += l.recipientLineTotal();
        cbase += l.customerLineTotal();
      }
      final ei = _selectedExpense;
      double markup = 0;
      if (ei != null && ei.markupEnabled) {
        final p = double.tryParse((ei.markupPercent ?? '0').replaceAll(',', '.')) ?? 0;
        markup = cbase * (p / 100.0);
      }
      final customerTotal = cbase + markup;
      final profit = cbase - rec;
      return (recipient: rec, customerBase: cbase, markup: markup, customerTotal: customerTotal, profit: profit);
    }
    final rec = double.tryParse(_manualRecipientCtrl.text.replaceAll(',', '.')) ?? 0;
    final cbase = double.tryParse(_manualCustomerCtrl.text.replaceAll(',', '.')) ?? 0;
    final ei = _selectedExpense;
    double markup = 0;
    if (ei != null && ei.markupEnabled) {
      final p = double.tryParse((ei.markupPercent ?? '0').replaceAll(',', '.')) ?? 0;
      markup = cbase * (p / 100.0);
    }
    final customerTotal = cbase + markup;
    final profit = cbase - rec;
    return (recipient: rec, customerBase: cbase, markup: markup, customerTotal: customerTotal, profit: profit);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final eid = _expenseItemId;
    final rid = _recipientCounterpartyId;
    if (eid == null || rid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportCreateMissingFields)));
      return;
    }

    final List<Map<String, dynamic>> requestLines;
    if (_hasLines) {
      requestLines = [for (final l in _lines) l.toRequestLine()];
    } else {
      final r = double.tryParse(_manualRecipientCtrl.text.replaceAll(',', '.')) ?? 0;
      final c = double.tryParse(_manualCustomerCtrl.text.replaceAll(',', '.')) ?? 0;
      if (r <= 0 || c <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportCreateMissingManualTotals)));
        return;
      }
      requestLines = [
        ReportLineData.custom(
          name: l10n.reportManualLineTitle,
          quantity: '1',
          recipientUnitPrice: r.toStringAsFixed(2),
          customerUnitPrice: c.toStringAsFixed(2),
        ).toRequestLine(),
      ];
    }

    setState(() => _submitting = true);
    try {
      await ref.read(reportsRepositoryProvider).createReport(
            companyId: widget.companyId,
            projectId: widget.projectId,
            body: {
              'expense_item_id': eid,
              'recipient_counterparty_id': rid,
              'operation_date': _fmtDate(_operationDate),
              if (_commentCtrl.text.trim().isNotEmpty) 'comment': _commentCtrl.text.trim(),
              'lines': requestLines,
            },
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : l10n.transferActionError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabelRead(ref, widget.companyId, l10n);
    final pv = _previewTotals();
    final ei = _selectedExpense;
    final markupPct = ei?.markupPercent;
    final showMarkupBlock = ei != null && ei.markupEnabled && (markupPct != null && markupPct.isNotEmpty);

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.reportCreateFormationTitle,
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : _metaError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_metaError == '_generic' ? l10n.transferDetailErrorLoad : _metaError!),
                        const SizedBox(height: 16),
                        AppButton(label: l10n.retry, onPressed: _loadMeta),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionCard(
                        context,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.reportCreateProjectLabel, style: _labelStyle(context)),
                            subtitle: Text(widget.projectName, style: _valueStyle(context)),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.reportCreateOperationDate, style: _labelStyle(context)),
                            subtitle: Text(_fmtDate(_operationDate), style: _valueStyle(context)),
                            trailing: const Icon(Icons.calendar_today, color: AppColors.textSecondary),
                            onTap: _pickDate,
                          ),
                          const Divider(height: 24),
                          Text(l10n.reportCreateExpenseItem, style: _labelStyle(context)),
                          const SizedBox(height: 4),
                          InputDecorator(
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: _expenseItemId,
                                items: [
                                  for (final e in _expenseItems)
                                    DropdownMenuItem(
                                      value: e.id,
                                      child: Text(
                                        e.markupEnabled && (e.markupPercent?.isNotEmpty ?? false)
                                            ? '${e.name} (${e.markupPercent}%)'
                                            : e.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: (v) => setState(() => _expenseItemId = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _openPositionsEditor,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.list_alt_rounded, color: AppColors.accent.withValues(alpha: 0.9)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.reportCreateLineSection, style: _labelStyle(context)),
                                        const SizedBox(height: 4),
                                        Text(
                                          l10n.reportPositionsRowSubtitle(
                                            _lines.length,
                                            pv.recipient.toStringAsFixed(2),
                                          ),
                                          style: TextStyle(
                                            color: _hasLines ? AppColors.warning : AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        context,
                        children: [
                          Text(l10n.reportCreateRecipient, style: _labelStyle(context)),
                          const SizedBox(height: 4),
                          InputDecorator(
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: _recipientCounterpartyId,
                                items: [
                                  for (final r in _recipients)
                                    DropdownMenuItem(value: r.id, child: Text(r.counterpartyName)),
                                ],
                                onChanged: (v) => setState(() => _recipientCounterpartyId = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_hasLines) ...[
                            _lockedAmountTile(
                              context,
                              label: l10n.reportManualRecipientTotal,
                              value: pv.recipient.toStringAsFixed(2),
                            ),
                            _lockedAmountTile(
                              context,
                              label: l10n.reportManualCustomerBase,
                              value: pv.customerBase.toStringAsFixed(2),
                            ),
                            if (showMarkupBlock)
                              _lockedAmountTile(
                                context,
                                label: '${l10n.reportCreatePreviewMarkup} ($markupPct%)',
                                value: pv.markup.toStringAsFixed(2),
                                valueColor: AppColors.accent,
                              ),
                            if (showMarkupBlock)
                              _lockedAmountTile(
                                context,
                                label: l10n.reportCreatePreviewCustomerTotal,
                                value: pv.customerTotal.toStringAsFixed(2),
                                valueColor: AppColors.warning,
                              ),
                            _lockedAmountTile(
                              context,
                              label: l10n.reportCreatePreviewProfit,
                              value: pv.profit.toStringAsFixed(2),
                              valueColor: AppColors.success,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                l10n.reportAmountsLockedFromLines,
                                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                              ),
                            ),
                          ] else ...[
                            AppInput(
                              controller: _manualRecipientCtrl,
                              label: l10n.reportManualRecipientTotal,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              suffix: const Icon(Icons.calculate_outlined, color: AppColors.textSecondary),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 8),
                            AppInput(
                              controller: _manualCustomerCtrl,
                              label: l10n.reportManualCustomerBase,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              suffix: const Icon(Icons.calculate_outlined, color: AppColors.textSecondary),
                              onChanged: (_) => setState(() {}),
                            ),
                            if (showMarkupBlock) ...[
                              const SizedBox(height: 12),
                              Text(
                                '${l10n.reportCreatePreviewMarkup} ($markupPct%): ${pv.markup.toStringAsFixed(2)}',
                                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${l10n.reportCreatePreviewCustomerTotal}: ${pv.customerTotal.toStringAsFixed(2)}',
                                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              '${l10n.reportCreatePreviewProfit}: ${pv.profit.toStringAsFixed(2)}',
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.reportCreatePreviewNote,
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 16),
                      AppInput(controller: _commentCtrl, label: l10n.reportCreateCommentLabel, maxLines: 3),
                      const SizedBox(height: 24),
                      AppButton(
                        label: l10n.reportActionSubmit,
                        loading: _submitting,
                        onPressed: _submitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
    );
  }

  TextStyle _labelStyle(BuildContext context) =>
      TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55), fontWeight: FontWeight.w500);

  TextStyle _valueStyle(BuildContext context) =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _lockedAmountTile(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final color = valueColor ?? AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75)))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 6),
          const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
