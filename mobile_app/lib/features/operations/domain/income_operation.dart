import 'operation_status.dart';
import 'operation_type.dart';

/// ТЗ-06: модель поступления из API (`income`).
class IncomeOperation {
  final int id;
  final int operationId;
  final int projectId;
  final String amount;
  final String? comment;
  final OperationStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? projectName;
  final String? initiatorDisplayName;
  final String? projectHeadDisplayName;
  final String? customerDisplayName;

  const IncomeOperation({
    required this.id,
    required this.operationId,
    required this.projectId,
    required this.amount,
    required this.comment,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.projectName,
    this.initiatorDisplayName,
    this.projectHeadDisplayName,
    this.customerDisplayName,
  });

  factory IncomeOperation.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    String readAmount(dynamic v) {
      if (v == null) return '0.00';
      if (v is String) return v;
      if (v is num) return v.toStringAsFixed(2);
      return v.toString();
    }

    String? readOptString(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      return v.toString();
    }

    String? participantName(dynamic block) {
      if (block is! Map) return null;
      final m = block.cast<String, dynamic>();
      final n = m['full_name'];
      if (n == null || (n is String && n.trim().isEmpty)) return null;
      return n.toString();
    }

    return IncomeOperation(
      id: readInt(json['id']),
      operationId: readInt(json['operation_id']),
      projectId: readInt(json['project_id']),
      amount: readAmount(json['amount']),
      comment: readOptString(json['comment']),
      status: OperationStatus.fromJson((json['operation_status'] ?? '').toString()),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      projectName: readOptString(json['project_name']),
      initiatorDisplayName: participantName(json['initiator']),
      projectHeadDisplayName: participantName(json['project_head']),
      customerDisplayName: participantName(json['customer']),
    );
  }

  bool get isStatusTerminal => status.isTerminalForOperationType(OperationType.income);
}
