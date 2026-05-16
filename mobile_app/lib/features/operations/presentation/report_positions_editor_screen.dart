import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../../price_lists/data/price_lists_repository.dart';
import '../../price_lists/providers.dart';
import '../domain/report_line_data.dart';

class _GroupBlock {
  final int groupId;
  final String name;
  final List<PriceListPositionRow> positions;

  const _GroupBlock({required this.groupId, required this.name, required this.positions});
}

class _Pick {
  bool on = false;
}

/// Полноэкранный редактор позиций отчёта: вкладки «Все позиции» / «Добавлено», прайсы проекта, custom-строки.
class ReportPositionsEditorScreen extends ConsumerStatefulWidget {
  final int companyId;
  final int projectId;
  final String projectName;
  final List<ReportLineData> initialLines;

  const ReportPositionsEditorScreen({
    super.key,
    required this.companyId,
    required this.projectId,
    required this.projectName,
    required this.initialLines,
  });

  @override
  ConsumerState<ReportPositionsEditorScreen> createState() => _ReportPositionsEditorScreenState();
}

class _ReportPositionsEditorScreenState extends ConsumerState<ReportPositionsEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<ReportLineData> _added;
  final Map<String, TextEditingController> _qtyCtrls = {};
  final Map<String, _Pick> _picks = {};

  List<ProjectAttachedPriceList> _attached = [];
  ProjectAttachedPriceList? _activePl;
  List<_GroupBlock> _groups = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _added = [for (final e in widget.initialLines) e];
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      final i = _tabController.index;
      if (_tabController.indexIsChanging) return;
      if (i != _tabIndex) setState(() => _tabIndex = i);
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await ref.read(priceListsRepositoryProvider).listProjectPriceLists(
            companyId: widget.companyId,
            projectId: widget.projectId,
          );
      if (!mounted) return;
      final active = rows.where((r) => r.isActive && (r.deletedAt == null || r.deletedAt!.isEmpty)).toList();
      setState(() {
        _attached = active;
        _activePl = active.isNotEmpty ? active.first : null;
        _loading = false;
      });
      if (_activePl != null) {
        await _reloadPriceListPositions();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  String _posKey(int plId, int gId, int posId) => '$plId-$gId-$posId';

  TextEditingController _qtyController(String key) {
    return _qtyCtrls.putIfAbsent(key, () => TextEditingController(text: '1'));
  }

  Future<void> _reloadPriceListPositions() async {
    final pl = _activePl;
    if (pl == null) {
      setState(() => _groups = []);
      return;
    }
    setState(() {
      _picks.clear();
      for (final c in _qtyCtrls.values) {
        c.dispose();
      }
      _qtyCtrls.clear();
    });
    try {
      final detail = await ref.read(priceListsRepositoryProvider).getPriceList(
            companyId: widget.companyId,
            priceListId: pl.priceListId,
          );
      final blocks = <_GroupBlock>[];
      for (final g in detail.groups) {
        final acc = <PriceListPositionRow>[];
        var page = 1;
        while (true) {
          final pageData = await ref.read(priceListsRepositoryProvider).listPositions(
                companyId: widget.companyId,
                priceListId: pl.priceListId,
                groupId: g.id,
                page: page,
              );
          acc.addAll(pageData.items);
          if (!pageData.pagination.hasMore) break;
          page++;
        }
        if (acc.isNotEmpty) {
          blocks.add(_GroupBlock(groupId: g.id, name: g.name, positions: acc));
        }
      }
      if (!mounted) return;
      setState(() => _groups = blocks);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _confirmSelections() {
    final pl = _activePl;
    if (pl == null) return;
    var addedAny = false;
    for (final g in _groups) {
      for (final p in g.positions) {
        final k = _posKey(pl.priceListId, g.groupId, p.id);
        final pick = _picks[k];
        if (pick == null || !pick.on) continue;
        final qStr = _qtyController(k).text.trim().replaceAll(',', '.');
        final q = double.tryParse(qStr) ?? 0;
        if (q <= 0) continue;
        final u = p.unit;
        _added.add(
          ReportLineData.fromPriceList(
            priceListId: pl.priceListId,
            groupId: g.groupId,
            positionId: p.id,
            name: p.serviceName,
            unitName: u?.name ?? 'pc',
            unitShortName: u?.shortName ?? 'pc',
            unitId: u?.id,
            quantity: qStr,
            recipientUnitPrice: p.recipientUnitPrice,
            customerUnitPrice: p.customerUnitPrice,
          ),
        );
        addedAny = true;
        pick.on = false;
        _qtyController(k).text = '1';
      }
    }
    if (!addedAny) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.reportPositionsNothingSelected)));
      return;
    }
    setState(() {});
    _tabController.animateTo(1);
  }

  Future<void> _showAddCustom() async {
    final units = await ref.read(unitsListProvider(widget.companyId).future);
    if (!mounted) return;
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final ruCtrl = TextEditingController();
    final cuCtrl = TextEditingController();
    final unitNameCtrl = TextEditingController(text: 'pc');
    final unitShortCtrl = TextEditingController(text: 'pc');
    UnitRow? unit = units.isNotEmpty ? units.first : null;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(
                builder: (ctx, setM) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(context.l10n.reportPositionsAddCustomTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      AppInput(controller: nameCtrl, label: context.l10n.reportCreateLineName),
                      const SizedBox(height: 8),
                      if (units.isNotEmpty)
                        InputDecorator(
                          decoration: InputDecoration(labelText: context.l10n.reportPositionsUnitLabel),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<UnitRow?>(
                              isExpanded: true,
                              value: unit,
                              items: [
                                for (final u in units)
                                  DropdownMenuItem(value: u, child: Text('${u.name} (${u.shortName})')),
                              ],
                              onChanged: (v) => setM(() => unit = v),
                            ),
                          ),
                        )
                      else ...[
                        AppInput(controller: unitNameCtrl, label: context.l10n.reportPositionsUnitLabel),
                        const SizedBox(height: 8),
                        AppInput(controller: unitShortCtrl, label: context.l10n.reportPositionsUnitShort),
                      ],
                      const SizedBox(height: 8),
                      AppInput(controller: qtyCtrl, label: context.l10n.reportCreateQuantity, keyboardType: TextInputType.number),
                      const SizedBox(height: 8),
                      AppInput(
                        controller: ruCtrl,
                        label: context.l10n.reportCreateRecipientUnitPrice,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 8),
                      AppInput(
                        controller: cuCtrl,
                        label: context.l10n.reportCreateCustomerUnitPrice,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: context.l10n.confirm,
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    if (ok == true && mounted) {
      final n = nameCtrl.text.trim();
      if (n.isEmpty) {
        nameCtrl.dispose();
        qtyCtrl.dispose();
        ruCtrl.dispose();
        cuCtrl.dispose();
        unitNameCtrl.dispose();
        unitShortCtrl.dispose();
        return;
      }
      setState(() {
        _added.add(
          ReportLineData.custom(
            name: n,
            unitName: units.isNotEmpty
                ? (unit?.name ?? 'pc')
                : (unitNameCtrl.text.trim().isEmpty ? 'pc' : unitNameCtrl.text.trim()),
            unitShortName: units.isNotEmpty
                ? (unit?.shortName ?? 'pc')
                : (unitShortCtrl.text.trim().isEmpty ? 'pc' : unitShortCtrl.text.trim()),
            unitId: units.isNotEmpty ? unit?.id : null,
            quantity: qtyCtrl.text.trim(),
            recipientUnitPrice: ruCtrl.text.trim().isEmpty ? '0' : ruCtrl.text.trim(),
            customerUnitPrice: cuCtrl.text.trim().isEmpty ? '0' : cuCtrl.text.trim(),
          ),
        );
      });
    }
    nameCtrl.dispose();
    qtyCtrl.dispose();
    ruCtrl.dispose();
    cuCtrl.dispose();
    unitNameCtrl.dispose();
    unitShortCtrl.dispose();
  }

  Future<void> _editLineQty(int index) async {
    final line = _added[index];
    final ctrl = TextEditingController(text: line.quantity);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.reportCreateQuantity),
        content: TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.confirm)),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        _added[index] = line.copyWith(quantity: ctrl.text.trim().replaceAll(',', '.'));
      });
    }
    ctrl.dispose();
  }

  bool _positionMatchesSearch(PriceListPositionRow p) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;
    final blob = '${p.serviceName} ${p.recipientUnitPrice} ${p.customerUnitPrice}'.toLowerCase();
    return blob.contains(q);
  }

  List<_GroupBlock> get _filteredGroups {
    if (_search.trim().isEmpty) return _groups;
    return _groups
        .map(
          (g) => _GroupBlock(
            groupId: g.groupId,
            name: g.name,
            positions: g.positions.where(_positionMatchesSearch).toList(),
          ),
        )
        .where((g) => g.positions.isNotEmpty)
        .toList();
  }

  void _finish() {
    Navigator.of(context).pop(List<ReportLineData>.from(_added));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabelRead(ref, widget.companyId, l10n);

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
            : Column(
                children: [
                  Material(
                    color: AppColors.surface,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.accent,
                      labelColor: AppColors.accent,
                      unselectedLabelColor: AppColors.textSecondary,
                      tabs: [
                        Tab(text: l10n.reportPositionsTabAll),
                        Tab(text: l10n.reportPositionsTabAddedCount(_added.length)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllTab(context),
                        _buildAddedTab(context),
                      ],
                    ),
                  ),
                ],
              );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && context.mounted) {
          _finish();
        }
      },
      child: AppScaffold(
        headerUserName: userName.isEmpty ? null : userName,
        headerRoleLabel: roleLabel,
        title: l10n.reportPositionsEditorTitle,
        subtitle: widget.projectName,
        actions: [
          TextButton(onPressed: _finish, child: Text(l10n.reportPositionsDone)),
        ],
        bottomNavigationBar: _tabIndex == 0 && _activePl != null && _groups.isNotEmpty
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _tabController.animateTo(1),
                          child: Text(l10n.reportPositionsGoToAdded),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: l10n.reportPositionsConfirmSelection,
                          onPressed: _confirmSelections,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        floatingActionButton: _tabIndex == 1
            ? FloatingActionButton.extended(
                onPressed: _showAddCustom,
                icon: const Icon(Icons.add),
                label: Text(l10n.reportPositionsAddCustomFab),
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.bg,
              )
            : null,
        body: body,
      ),
    );
  }

  Widget _buildAllTab(BuildContext context) {
    final l10n = context.l10n;
    if (_attached.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.reportPositionsNoPriceLists, textAlign: TextAlign.center),
        ),
      );
    }
    final pl = _activePl!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.reportPositionsPriceListLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProjectAttachedPriceList>(
              isExpanded: true,
              value: _activePl,
              items: [
                for (final a in _attached)
                  DropdownMenuItem(value: a, child: Text(a.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() {
                  _activePl = v;
                  _picks.clear();
                });
                await _reloadPriceListPositions();
                if (mounted) setState(() {});
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: l10n.reportPositionsSearch,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: 12),
        for (final g in _filteredGroups) ...[
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            children: [
              for (final p in g.positions)
                Builder(
                  builder: (context) {
                    final k = _posKey(pl.priceListId, g.groupId, p.id);
                    final pick = _picks.putIfAbsent(k, () => _Pick());
                    final u = p.unit;
                    final sub = '${l10n.reportPositionsUnitShort}: ${u?.shortName ?? '—'} · ${p.recipientUnitPrice} / ${p.customerUnitPrice}';
                    return CheckboxListTile(
                      value: pick.on,
                      onChanged: (v) => setState(() {
                        pick.on = v ?? false;
                        if (pick.on) {
                          _qtyController(k).text = _qtyController(k).text.trim().isEmpty ? '1' : _qtyController(k).text;
                        }
                      }),
                      title: Text(p.serviceName, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
                      secondary: SizedBox(
                        width: 64,
                        child: TextField(
                          controller: _qtyController(k),
                          enabled: pick.on,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(isDense: true, hintText: '1'),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAddedTab(BuildContext context) {
    final l10n = context.l10n;
    if (_added.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.reportPositionsAddedEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: _added.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final line = _added[i];
        final tot = '${line.recipientLineTotal().toStringAsFixed(2)} · ${line.customerLineTotal().toStringAsFixed(2)}';
        return ListTile(
          title: Text(line.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${l10n.reportCreateQuantity}: ${line.quantity} · $tot',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editLineQty(i)),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _added.removeAt(i)),
              ),
            ],
          ),
        );
      },
    );
  }
}
