import 'income_operation.dart';
import 'transfer_operation.dart';

/// Элемент объединённой ленты `/operations/history` (ТЗ-06.1).
class AggregatedHistoryItem {
  final String operationKind;
  final int projectId;
  final TransferOperation? transfer;
  final IncomeOperation? income;

  const AggregatedHistoryItem({
    required this.operationKind,
    required this.projectId,
    this.transfer,
    this.income,
  });

  factory AggregatedHistoryItem.fromJson(Map<String, dynamic> json) {
    final kind = (json['operation_kind'] ?? '').toString();
    final projectId = () {
      final v = json['project_id'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }();

    if (kind == 'transfer') {
      final raw = json['transfer'];
      if (raw is Map) {
        return AggregatedHistoryItem(
          operationKind: kind,
          projectId: projectId,
          transfer: TransferOperation.fromJson(raw.cast<String, dynamic>()),
        );
      }
    }
    if (kind == 'income') {
      final raw = json['income'];
      if (raw is Map) {
        return AggregatedHistoryItem(
          operationKind: kind,
          projectId: projectId,
          income: IncomeOperation.fromJson(raw.cast<String, dynamic>()),
        );
      }
    }

    return AggregatedHistoryItem(operationKind: kind, projectId: projectId);
  }

  bool get isTransfer => operationKind == 'transfer';
  bool get isIncome => operationKind == 'income';
}
