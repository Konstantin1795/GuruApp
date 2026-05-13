import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_input.dart';
import '../data/transfers_api.dart';
import '../providers.dart';

void reportAttachSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Bottom sheet: выбрать отчёт проекта и прикрепить текущий перевод (`POST …/reports/{id}/transfer-links`).
Future<bool> showAttachReportToTransferSheet(
  BuildContext context, {
  required TransferApiScope apiScope,
  required int companyId,
  required int projectId,
  required String transferOperationNumber,
  int? excludeReportIdLinked,
}) async {
  final v = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.72,
          child: _AttachReportToTransferBody(
            apiScope: apiScope,
            companyId: companyId,
            projectId: projectId,
            transferOperationNumber: transferOperationNumber,
            excludeReportIdLinked: excludeReportIdLinked,
          ),
        ),
      ),
    ),
  );
  return v == true;
}

class _AttachReportToTransferBody extends ConsumerStatefulWidget {
  final TransferApiScope apiScope;
  final int companyId;
  final int projectId;
  final String transferOperationNumber;
  final int? excludeReportIdLinked;

  const _AttachReportToTransferBody({
    required this.apiScope,
    required this.companyId,
    required this.projectId,
    required this.transferOperationNumber,
    this.excludeReportIdLinked,
  });

  @override
  ConsumerState<_AttachReportToTransferBody> createState() => _AttachReportToTransferBodyState();
}

class _AttachReportToTransferBodyState extends ConsumerState<_AttachReportToTransferBody> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _reports = [];
  bool _loading = false;
  String? _error;
  int? _attachingReportId;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    scheduleMicrotask(_fetch);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _fetch);
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = _searchCtrl.text.trim();
      final list = await ref.read(reportsRepositoryProvider).listReports(
            scope: widget.apiScope,
            companyId: widget.companyId,
            projectId: widget.projectId,
            search: q.isEmpty ? null : q,
          );
      if (!mounted) return;
      var rows = list;
      final ex = widget.excludeReportIdLinked;
      if (ex != null) {
        rows = rows.where((r) => _readInt(r['id']) != ex).toList(growable: false);
      }
      setState(() {
        _reports = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : context.l10n.errorGeneric;
      });
    }
  }

  Future<void> _attach(Map<String, dynamic> report) async {
    final id = _readInt(report['id']);
    if (id <= 0) return;
    setState(() => _attachingReportId = id);
    try {
      await ref.read(reportsRepositoryProvider).attachTransferLinkToReport(
            scope: widget.apiScope,
            companyId: widget.companyId,
            projectId: widget.projectId,
            reportId: id,
            operationNumber: widget.transferOperationNumber,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _attachingReportId = null);
      reportAttachSnack(context, e is ApiException ? e.message : context.l10n.errorGeneric);
    }
  }

  static int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static String _reportTitle(Map<String, dynamic> r) {
    final n = r['operation_number']?.toString();
    if (n != null && n.trim().isNotEmpty) return n.trim();
    return 'REP #${r['id']}';
  }

  static String _reportSubtitle(Map<String, dynamic> r) {
    final parts = <String>[];
    final date = r['operation_date']?.toString();
    if (date != null && date.isNotEmpty) parts.add(date);
    final ct = r['customer_total_amount']?.toString();
    final ra = r['recipient_amount']?.toString();
    if (ct != null && ct.isNotEmpty) {
      parts.add(ct);
    } else if (ra != null && ra.isNotEmpty) {
      parts.add(ra);
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.transferAttachToReportTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(onPressed: () => Navigator.of(context).pop(false), icon: const Icon(Icons.close)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: AppInput(
            controller: _searchCtrl,
            label: l10n.transferAttachToReportSearchHint,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        Expanded(
          child: _loading && _reports.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: _reports.length,
                  itemBuilder: (context, i) {
                    final r = _reports[i];
                    final id = _readInt(r['id']);
                    final busy = _attachingReportId != null;
                    return ListTile(
                      title: Text(_reportTitle(r)),
                      subtitle: Text(
                        _reportSubtitle(r),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: busy
                          ? (_attachingReportId == id
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null)
                          : const Icon(Icons.link),
                      onTap: busy ? null : () => _attach(r),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
