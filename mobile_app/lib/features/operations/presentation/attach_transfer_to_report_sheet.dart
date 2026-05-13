import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_input.dart';
import '../data/transfers_api.dart';
import '../domain/transfer_operation.dart';
import '../providers.dart';

/// Bottom sheet: выбрать перевод проекта и прикрепить к отчёту (`POST …/transfer-links`).
Future<bool> showAttachTransferToReportSheet(
  BuildContext context, {
  required TransferApiScope apiScope,
  required int companyId,
  required int projectId,
  required int reportId,
  Set<String> excludeOperationNumbers = const {},
}) async {
  final v = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.72,
          child: _AttachTransferToReportBody(
            apiScope: apiScope,
            companyId: companyId,
            projectId: projectId,
            reportId: reportId,
            excludeOperationNumbers: excludeOperationNumbers,
          ),
        ),
      ),
    ),
  );
  return v == true;
}

class _AttachTransferToReportBody extends ConsumerStatefulWidget {
  final TransferApiScope apiScope;
  final int companyId;
  final int projectId;
  final int reportId;
  final Set<String> excludeOperationNumbers;

  const _AttachTransferToReportBody({
    required this.apiScope,
    required this.companyId,
    required this.projectId,
    required this.reportId,
    required this.excludeOperationNumbers,
  });

  @override
  ConsumerState<_AttachTransferToReportBody> createState() => _AttachTransferToReportBodyState();
}

class _AttachTransferToReportBodyState extends ConsumerState<_AttachTransferToReportBody> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<TransferOperation> _items = [];
  bool _loading = false;
  String? _error;
  String? _attachingNum;

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
      final page = await ref.read(transfersRepositoryProvider).list(
            scope: widget.apiScope,
            companyId: widget.companyId,
            projectId: widget.projectId,
            page: 1,
            perPage: 40,
            search: q.isEmpty ? null : q,
          );
      if (!mounted) return;
      final ex = widget.excludeOperationNumbers.map((e) => e.trim().toUpperCase()).toSet();
      final items = page.items.where((t) {
        final n = (t.operationNumber ?? '').trim().toUpperCase();
        return n.isEmpty || !ex.contains(n);
      }).toList(growable: false);
      setState(() {
        _items = items;
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

  Future<void> _attach(TransferOperation t) async {
    final num = t.operationNumber?.trim();
    if (num == null || num.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.reportAttachTransferMissingNumber)));
      return;
    }
    setState(() => _attachingNum = num);
    try {
      await ref.read(reportsRepositoryProvider).attachTransferLinkToReport(
            scope: widget.apiScope,
            companyId: widget.companyId,
            projectId: widget.projectId,
            reportId: widget.reportId,
            operationNumber: num,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _attachingNum = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : context.l10n.errorGeneric)),
      );
    }
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
                  l10n.reportAttachTransferTitle,
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
            label: l10n.reportAttachTransferSearchHint,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        Expanded(
          child: _loading && _items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final t = _items[i];
                    final num = t.operationNumber ?? '—';
                    final busy = _attachingNum != null;
                    final sub = _transferSubtitle(t);
                    return ListTile(
                      title: Text(num),
                      subtitle: Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: busy
                          ? (_attachingNum == t.operationNumber
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null)
                          : const Icon(Icons.link),
                      onTap: busy ? null : () => _attach(t),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static String _transferSubtitle(TransferOperation t) {
    final parts = <String>[t.amount];
    final ca = t.createdAt;
    if (ca != null) {
      final l = ca.toLocal();
      parts.add(
        '${l.year.toString().padLeft(4, '0')}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}',
      );
    }
    if ((t.receiverName ?? '').trim().isNotEmpty) {
      parts.add(t.receiverName!.trim());
    }
    return parts.join(' · ');
  }
}
