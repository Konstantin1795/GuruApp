import 'operation_status.dart';
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
  });

  factory TransferOperation.fromJson(Map<String, dynamic> json) => TransferOperation(
        id: json['id'] as int,
        operationId: json['operation_id'] as int,
        projectId: json['project_id'] as int,
        initiatorProjectParticipantId: json['initiator_project_participant_id'] as int,
        senderProjectParticipantId: json['sender_project_participant_id'] as int,
        receiverProjectParticipantId: json['receiver_project_participant_id'] as int,
        senderName: json['sender_name'] as String?,
        receiverName: json['receiver_name'] as String?,
        targetType: TransferTargetType.fromJson(json['transfer_target_type'] as String),
        amount: json['amount'] as String,
        comment: json['comment'] as String?,
        status: OperationStatus.fromJson(json['operation_status'] as String),
        createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
        updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? ''),
      );
}
