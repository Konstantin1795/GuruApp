import 'income_operation.dart';
import 'operation_status_history_entry.dart';

class IncomeDetailView {
  final IncomeOperation income;
  final Map<String, bool> availableActions;
  final List<OperationStatusHistoryEntry> statusHistory;

  const IncomeDetailView({
    required this.income,
    required this.availableActions,
    required this.statusHistory,
  });

  factory IncomeDetailView.fromShowJson(Map<String, dynamic> data) {
    final incomeMap = (data['income'] as Map).cast<String, dynamic>();
    final rawActions = data['available_actions'];
    final Map<String, bool> actions = {};
    if (rawActions is Map) {
      for (final e in rawActions.entries) {
        actions[e.key.toString()] = e.value == true;
      }
    }

    final histRaw = incomeMap['status_history'];
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

    return IncomeDetailView(
      income: IncomeOperation.fromJson(incomeMap),
      availableActions: actions,
      statusHistory: history,
    );
  }
}
