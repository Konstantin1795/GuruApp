import 'operation_status_history_entry.dart';
import 'transfer_operation.dart';

class TransferDetailView {
  final TransferOperation transfer;
  final Map<String, bool> availableActions;
  final List<OperationStatusHistoryEntry> statusHistory;

  const TransferDetailView({
    required this.transfer,
    required this.availableActions,
    required this.statusHistory,
  });

  factory TransferDetailView.fromShowJson(Map<String, dynamic> data) {
    final transferMap = (data['transfer'] as Map).cast<String, dynamic>();
    final rawActions = data['available_actions'];
    final Map<String, bool> actions = {};
    if (rawActions is Map) {
      for (final e in rawActions.entries) {
        actions[e.key.toString()] = e.value == true;
      }
    }

    final histRaw = transferMap['status_history'];
    final List<OperationStatusHistoryEntry> history = [];
    if (histRaw is List) {
      for (final item in histRaw) {
        if (item is Map) {
          history.add(OperationStatusHistoryEntry.fromJson(item.cast<String, dynamic>()));
        }
      }
    }

    history.sort((a, b) {
      final ta = a.createdAt;
      final tb = b.createdAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return -1;
      if (tb == null) return 1;
      return ta.compareTo(tb);
    });

    return TransferDetailView(
      transfer: TransferOperation.fromJson(transferMap),
      availableActions: actions,
      statusHistory: history,
    );
  }
}
