import 'operation_status.dart';
import 'operation_type.dart';
import 'transfer_target_type.dart';

class TransferOperation {
  final int id;
  final int operationId;
  final int projectId;
  final int initiatorProjectParticipantId;
  final int senderProjectParticipantId;
  final int receiverProjectParticipantId;
  final String? senderName;
  final String? receiverName;
  final TransferTargetType targetType;
  final String amount;
  final String? comment;
  final OperationStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  /// Если отдано API (агрегированный список по компании).
  final String? projectName;

  const TransferOperation({
    required this.id,
    required this.operationId,
    required this.projectId,
    required this.initiatorProjectParticipantId,
    required this.senderProjectParticipantId,
    required this.receiverProjectParticipantId,
    required this.senderName,
    required this.receiverName,
    required this.targetType,
    required this.amount,
    required this.comment,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.projectName,
  });

  factory TransferOperation.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    String readAmount(dynamic v) {
      if (v == null) return '0.00';
      if (v is String) return v;
      if (v is num) {
        return v.toStringAsFixed(2);
      }
      return v.toString();
    }

    return TransferOperation(
      id: readInt(json['id']),
      operationId: readInt(json['operation_id']),
      projectId: readInt(json['project_id']),
      initiatorProjectParticipantId: readInt(json['initiator_project_participant_id']),
      senderProjectParticipantId: readInt(json['sender_project_participant_id']),
      receiverProjectParticipantId: readInt(json['receiver_project_participant_id']),
      senderName: json['sender_name'] as String?,
      receiverName: json['receiver_name'] as String?,
      targetType: TransferTargetType.fromJson((json['transfer_target_type'] ?? '').toString()),
      amount: readAmount(json['amount']),
      comment: json['comment'] as String?,
      status: OperationStatus.fromJson((json['operation_status'] ?? '').toString()),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      projectName: json['project_name'] as String?,
    );
  }

  /// Transfer lifecycle terminality (REJECTED is intermediate).
  bool get isStatusTerminal => status.isTerminalForOperationType(OperationType.transfer);
}
