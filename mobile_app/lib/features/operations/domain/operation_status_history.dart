import 'operation_status.dart';

class OperationStatusHistory {
  final int id;
  final int operationId;
  final OperationStatus? fromStatus;
  final OperationStatus toStatus;
  final int? changedByProjectParticipantId;
  final DateTime? createdAt;

  const OperationStatusHistory({
    required this.id,
    required this.operationId,
    required this.fromStatus,
    required this.toStatus,
    required this.changedByProjectParticipantId,
    required this.createdAt,
  });

  factory OperationStatusHistory.fromJson(Map<String, dynamic> json) =>
      OperationStatusHistory(
        id: json['id'] as int,
        operationId: json['operation_id'] as int,
        fromStatus: json['from_status'] == null
            ? null
            : OperationStatus.fromJson(json['from_status'] as String),
        toStatus: OperationStatus.fromJson(json['to_status'] as String),
        changedByProjectParticipantId:
            json['changed_by_project_participant_id'] as int?,
        createdAt:
            DateTime.tryParse((json['created_at'] as String?) ?? ''),
      );
}
