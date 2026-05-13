import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../../projects/domain/project_expense_item.dart';
import '../../projects/providers.dart';
import '../providers.dart';
import 'report_price_list_line_picker_sheet.dart';

/// Создание отчёта (company-workspace). Итоги на сервере; экран показывает только preview.
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

class _LineDraft {
  _LineDraft({
    required this.sourceType,
    this.priceListId,
    this.groupId,
    this.positionId,
    required String name,
    required String qty,
    required String ru,
    required String cu,
    int? unitId,
    String? unitName,
    String? unitShort,
  })  : nameCtrl = TextEditingController(text: name),
        qtyCtrl = TextEditingController(text: qty),
        ruCtrl = TextEditingController(text: ru),
        cuCtrl = TextEditingController(text: cu),
        _unitIdFallback = unitId,
        _unitNameFallback = unitName,
        _unitShortFallback = unitShort;

  factory _LineDraft.custom() => _LineDraft(
        sourceType: 'CUSTOM',
        name: 'Work',
        qty: '1',
        ru: '100.00',
        cu: '120.00',
      );

  factory _LineDraft.fromPriceList(ReportPriceListPick p) {
    final u = p.unit;
    return _LineDraft(
      sourceType: 'PRICE_LIST',
      priceListId: p.priceListId,
      groupId: p.groupId,
      positionId: p.positionId,
      name: p.name,
      qty: '1',
      ru: p.recipientUnitPrice,
      cu: p.customerUnitPrice,
      unitId: u?.id,
      unitName: u?.name ?? 'pc',
      unitShort: u?.shortName ?? 'pc',
    );
  }

  final String sourceType;
  final int? priceListId;
  final int? groupId;
  final int? positionId;
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController ruCtrl;
  final TextEditingController cuCtrl;
  final int? _unitIdFallback;
  final String? _unitNameFallback;
  final String? _unitShortFallback;

  bool get isPriceList => sourceType == 'PRICE_LIST';

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    ruCtrl.dispose();
    cuCtrl.dispose();
  }

  Map<String, dynamic> toRequestLine() {
    final qty = qtyCtrl.text.trim();
    final ru = ruCtrl.text.trim();
    final cu = cuCtrl.text.trim();
    final rt = (double.tryParse(qty) ?? 0) * (double.tryParse(ru) ?? 0);
    final ct = (double.tryParse(qty) ?? 0) * (double.tryParse(cu) ?? 0);
    final name = nameCtrl.text.trim().isEmpty ? 'Line' : nameCtrl.text.trim();
    final unitName = _unitNameFallback ?? 'pc';
    final unitShort = _unitShortFallback ?? 'pc';
    return {
      'source_type': sourceType,
      if (priceListId != null) 'price_list_id': priceListId,
      if (groupId != null) 'price_list_group_id': groupId,
      if (positionId != null) 'price_list_position_id': positionId,
      'name': name,
      if (_unitIdFallback != null) 'unit_id': _unitIdFallback,
      'unit_name': unitName,
      'unit_short_name': unitShort,
      'quantity': qty,
      'recipient_unit_price': ru,
      'customer_unit_price': cu,
      'recipient_total': rt.toStringAsFixed(2),
      'customer_total': ct.toStringAsFixed(2),
    };
  }
}

class _CreateEditReportScreenState extends ConsumerState<CreateEditReportScreen> {
  final _commentCtrl = TextEditingController();

  int? _expenseItemId;
  int? _recipientCounterpartyId;
  DateTime _operationDate = DateTime.now();

  List<ProjectExpenseItemListRow> _expenseItems = [];
  List<ExpenseItemRecipientOption> _recipients = [];
  final List<_LineDraft> _lines = [];
  bool _loadingMeta = true;
  bool _submitting = false;
  String? _metaError;

  @override
  void initState() {
    super.initState();
    _lines.add(_LineDraft.custom());
    _loadMeta();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
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

  void _addCustomLine() {
    setState(() => _lines.add(_LineDraft.custom()));
  }

  void _removeLine(int i) {
    if (_lines.length <= 1) return;
    setState(() {
      final r = _lines.removeAt(i);
      r.dispose();
    });
  }

  Future<void> _addFromPriceList() async {
    final pick = await showReportPriceListLinePicker(
      context,
      companyId: widget.companyId,
      projectId: widget.projectId,
    );
    if (pick == null || !mounted) return;
    final draft = _LineDraft.fromPriceList(pick);
    setState(() => _lines.add(draft));
  }

  ({double recipient, double customerBase, double markup, double customerTotal, double profit}) _previewTotals() {
    double rec = 0;
    double cbase = 0;
    for (final l in _lines) {
      final qty = double.tryParse(l.qtyCtrl.text.trim()) ?? 0;
      final ru = double.tryParse(l.ruCtrl.text.trim()) ?? 0;
      final cu = double.tryParse(l.cuCtrl.text.trim()) ?? 0;
      rec += qty * ru;
      cbase += qty * cu;
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

  Future<void> _submit() async {
    final l10n = context.l10n;
    final eid = _expenseItemId;
    final rid = _recipientCounterpartyId;
    if (eid == null || rid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportCreateMissingFields)));
      return;
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
              'lines': [for (final l in _lines) l.toRequestLine()],
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

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.reportCreateTitle,
      subtitle: widget.projectName,
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
                      Text(l10n.reportCreateExpenseSection, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      InputDecorator(
                        decoration: InputDecoration(labelText: l10n.reportCreateExpenseItem),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: _expenseItemId,
                            items: [
                              for (final e in _expenseItems)
                                DropdownMenuItem(value: e.id, child: Text(e.name)),
                            ],
                            onChanged: (v) => setState(() => _expenseItemId = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: InputDecoration(labelText: l10n.reportCreateRecipient),
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
                      const SizedBox(height: 12),
                      ListTile(
                        title: Text(l10n.reportCreateOperationDate),
                        subtitle: Text(_fmtDate(_operationDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Text(l10n.reportCreateLineSection, style: const TextStyle(fontWeight: FontWeight.w700))),
                          TextButton(onPressed: _addCustomLine, child: Text(l10n.reportCreateAddCustomLine)),
                          TextButton(onPressed: _addFromPriceList, child: Text(l10n.reportCreateAddFromPriceList)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < _lines.length; i++) ...[
                        KeyedSubtree(
                          key: ObjectKey(_lines[i]),
                          child: _LineCard(
                            index: i,
                            line: _lines[i],
                            canRemove: _lines.length > 1,
                            onRemove: () => _removeLine(i),
                            onChanged: () => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(l10n.reportCreatePreviewTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('${l10n.reportCreatePreviewRecipient}: ${pv.recipient.toStringAsFixed(2)}'),
                      Text('${l10n.reportCreatePreviewCustomerBase}: ${pv.customerBase.toStringAsFixed(2)}'),
                      Text('${l10n.reportCreatePreviewMarkup}: ${pv.markup.toStringAsFixed(2)}'),
                      Text('${l10n.reportCreatePreviewCustomerTotal}: ${pv.customerTotal.toStringAsFixed(2)}'),
                      Text('${l10n.reportCreatePreviewProfit}: ${pv.profit.toStringAsFixed(2)}'),
                      const SizedBox(height: 6),
                      Text(
                        l10n.reportCreatePreviewNote,
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55)),
                      ),
                      const SizedBox(height: 12),
                      AppInput(controller: _commentCtrl, label: l10n.transferCommentLabel, maxLines: 3),
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
}

class _LineCard extends StatelessWidget {
  final int index;
  final _LineDraft line;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _LineCard({
    required this.index,
    required this.line,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '${l10n.reportCreateLineSection} ${index + 1}',
        suffixIcon: canRemove
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemove,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (line.isPriceList)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('PRICE_LIST', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            ),
          AppInput(
            controller: line.nameCtrl,
            label: l10n.reportCreateLineName,
            onChanged: (_) => onChanged(),
            enabled: !line.isPriceList,
          ),
          const SizedBox(height: 8),
          AppInput(
            controller: line.qtyCtrl,
            label: l10n.reportCreateQuantity,
            keyboardType: TextInputType.number,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          AppInput(
            controller: line.ruCtrl,
            label: l10n.reportCreateRecipientUnitPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          AppInput(
            controller: line.cuCtrl,
            label: l10n.reportCreateCustomerUnitPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}
