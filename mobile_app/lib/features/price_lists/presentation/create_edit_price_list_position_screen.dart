import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../data/price_lists_repository.dart';
import '../providers.dart';
import 'unit_picker_sheet.dart';

class CreateEditPriceListPositionScreen extends ConsumerStatefulWidget {
  final int companyId;
  final int priceListId;
  final int groupId;
  final int? positionId;

  const CreateEditPriceListPositionScreen({
    super.key,
    required this.companyId,
    required this.priceListId,
    required this.groupId,
    required this.positionId,
  });

  @override
  ConsumerState<CreateEditPriceListPositionScreen> createState() => _CreateEditPriceListPositionScreenState();
}

class _CreateEditPriceListPositionScreenState extends ConsumerState<CreateEditPriceListPositionScreen> {
  final _name = TextEditingController();
  final _rec = TextEditingController();
  final _cust = TextEditingController();
  UnitRow? _unit;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.positionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final key = (
          companyId: widget.companyId,
          priceListId: widget.priceListId,
          groupId: widget.groupId,
          search: '',
        );
        final page = await ref.read(priceListPositionsProvider(key).future);
        PriceListPositionRow? row;
        for (final p in page.items) {
          if (p.id == widget.positionId) {
            row = p;
            break;
          }
        }
        if (!mounted || row == null) return;
        final r = row;
        _name.text = r.serviceName;
        _rec.text = r.recipientUnitPrice;
        _cust.text = r.customerUnitPrice;
        setState(() => _unit = r.unit);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _rec.dispose();
    _cust.dispose();
    super.dispose();
  }

  Future<void> _pickUnit() async {
    final u = await showModalBottomSheet<UnitRow>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UnitPickerSheet(companyId: widget.companyId),
    );
    if (u != null) setState(() => _unit = u);
  }

  Future<void> _save() async {
    if (_unit == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.selectUnit)));
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(priceListsRepositoryProvider);
      if (widget.positionId == null) {
        await repo.createPosition(
          companyId: widget.companyId,
          priceListId: widget.priceListId,
          groupId: widget.groupId,
          serviceName: name,
          unitId: _unit!.id,
          recipientUnitPrice: _rec.text.trim(),
          customerUnitPrice: _cust.text.trim(),
        );
      } else {
        await repo.updatePosition(
          companyId: widget.companyId,
          priceListId: widget.priceListId,
          groupId: widget.groupId,
          positionId: widget.positionId!,
          body: {
            'service_name': name,
            'unit_id': _unit!.id,
            'recipient_unit_price': _rec.text.trim(),
            'customer_unit_price': _cust.text.trim(),
          },
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    if (widget.positionId == null) return;
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePriceListPosition),
        content: const Text(''),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(priceListsRepositoryProvider).deletePosition(
          companyId: widget.companyId,
          priceListId: widget.priceListId,
          groupId: widget.groupId,
          positionId: widget.positionId!,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabel(ref, widget.companyId, l10n);
    final isEdit = widget.positionId != null;

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: isEdit ? l10n.editPriceListPosition : l10n.createPriceListPosition,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppInput(controller: _name, label: l10n.serviceName, autofocus: !isEdit),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            title: Text(l10n.unitLabel),
            subtitle: Text(_unit == null ? l10n.selectUnit : '${_unit!.name} (${_unit!.shortName})'),
            trailing: const Icon(Icons.expand_more),
            onTap: _pickUnit,
          ),
          AppInput(
            controller: _rec,
            label: l10n.recipientUnitPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.md),
          AppInput(
            controller: _cust,
            label: l10n.customerUnitPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? l10n.loading : l10n.save),
          ),
          if (isEdit) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _loading ? null : _delete,
              child: Text(l10n.deletePriceListPosition, style: const TextStyle(color: Colors.redAccent)),
            ),
          ],
        ],
      ),
    );
  }
}
