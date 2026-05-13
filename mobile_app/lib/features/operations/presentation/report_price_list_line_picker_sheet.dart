import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../price_lists/data/price_lists_repository.dart';
import '../../price_lists/providers.dart';

/// Данные для строки отчёта `source_type: PRICE_LIST` (итоги пересчитает backend).
class ReportPriceListPick {
  final int priceListId;
  final int groupId;
  final int positionId;
  final String name;
  final UnitRow? unit;
  final String recipientUnitPrice;
  final String customerUnitPrice;

  const ReportPriceListPick({
    required this.priceListId,
    required this.groupId,
    required this.positionId,
    required this.name,
    required this.unit,
    required this.recipientUnitPrice,
    required this.customerUnitPrice,
  });
}

Future<ReportPriceListPick?> showReportPriceListLinePicker(
  BuildContext context, {
  required int companyId,
  required int projectId,
}) {
  return showModalBottomSheet<ReportPriceListPick>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.72,
          child: _ReportPriceListPickerBody(
            companyId: companyId,
            projectId: projectId,
          ),
        ),
      ),
    ),
  );
}

class _ReportPriceListPickerBody extends ConsumerStatefulWidget {
  final int companyId;
  final int projectId;

  const _ReportPriceListPickerBody({
    required this.companyId,
    required this.projectId,
  });

  @override
  ConsumerState<_ReportPriceListPickerBody> createState() => _ReportPriceListPickerBodyState();
}

class _ReportPriceListPickerBodyState extends ConsumerState<_ReportPriceListPickerBody> {
  bool _loadingLists = true;
  String? _error;
  List<ProjectAttachedPriceList> _attached = [];

  ProjectAttachedPriceList? _selectedPl;
  bool _loadingPositions = false;
  final _searchCtrl = TextEditingController();
  List<({int groupId, PriceListPositionRow pos})> _allPositions = [];

  @override
  void initState() {
    super.initState();
    _loadAttached();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAttached() async {
    setState(() {
      _loadingLists = true;
      _error = null;
    });
    try {
      final rows = await ref.read(priceListsRepositoryProvider).listProjectPriceLists(
            companyId: widget.companyId,
            projectId: widget.projectId,
          );
      if (!mounted) return;
      setState(() {
        _attached = rows.where((r) => r.isActive && (r.deletedAt == null || r.deletedAt!.isEmpty)).toList();
        _loadingLists = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLists = false;
        _error = e is ApiException ? e.message : context.l10n.errorGeneric;
      });
    }
  }

  Future<void> _selectPriceList(ProjectAttachedPriceList pl) async {
    setState(() {
      _selectedPl = pl;
      _loadingPositions = true;
      _error = null;
      _allPositions = [];
      _searchCtrl.clear();
    });
    try {
      final detail = await ref.read(priceListsRepositoryProvider).getPriceList(
            companyId: widget.companyId,
            priceListId: pl.priceListId,
          );
      final acc = <({int groupId, PriceListPositionRow pos})>[];
      for (final g in detail.groups) {
        var pageNum = 1;
        while (true) {
          final page = await ref.read(priceListsRepositoryProvider).listPositions(
                companyId: widget.companyId,
                priceListId: pl.priceListId,
                groupId: g.id,
                page: pageNum,
              );
          for (final p in page.items) {
            acc.add((groupId: g.id, pos: p));
          }
          if (!page.pagination.hasMore) break;
          pageNum++;
        }
      }
      if (!mounted) return;
      setState(() {
        _allPositions = acc;
        _loadingPositions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPositions = false;
        _error = e is ApiException ? e.message : context.l10n.errorGeneric;
      });
    }
  }

  List<({int groupId, PriceListPositionRow pos})> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _allPositions;
    return _allPositions.where((e) {
      final p = e.pos;
      final blob =
          '${p.serviceName} ${p.recipientUnitPrice} ${p.customerUnitPrice} ${p.profitAmount}'.toLowerCase();
      return blob.contains(q);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
          child: Row(
            children: [
              if (_selectedPl != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedPl = null;
                      _allPositions = [];
                      _searchCtrl.clear();
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              Expanded(
                child: Text(
                  _selectedPl == null ? l10n.reportPriceListPickerTitle : _selectedPl!.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (_selectedPl != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: l10n.reportAttachTransferSearchHint,
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        Expanded(
          child: _loadingLists
              ? const Center(child: CircularProgressIndicator())
              : _selectedPl == null
                  ? _buildListPicker()
                  : _loadingPositions
                      ? const Center(child: CircularProgressIndicator())
                      : _buildPositionPicker(),
        ),
      ],
    );
  }

  Widget _buildListPicker() {
    final l10n = context.l10n;
    if (_attached.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.reportPriceListPickerEmpty)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      itemCount: _attached.length,
      itemBuilder: (context, i) {
        final pl = _attached[i];
        return ListTile(
          title: Text(pl.name),
          subtitle: Text(pl.creatorDisplayName, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => _selectPriceList(pl),
        );
      },
    );
  }

  Widget _buildPositionPicker() {
    final rows = _filtered;
    if (rows.isEmpty) {
      return Center(child: Text(context.l10n.reportPriceListPickerEmpty));
    }
    final plId = _selectedPl!.priceListId;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final e = rows[i];
        final p = e.pos;
        return ListTile(
          title: Text(p.serviceName),
          subtitle: Text('${p.recipientUnitPrice} · ${p.customerUnitPrice}', maxLines: 1),
          onTap: () {
            Navigator.of(context).pop(
              ReportPriceListPick(
                priceListId: plId,
                groupId: e.groupId,
                positionId: p.id,
                name: p.serviceName,
                unit: p.unit,
                recipientUnitPrice: p.recipientUnitPrice,
                customerUnitPrice: p.customerUnitPrice,
              ),
            );
          },
        );
      },
    );
  }
}
