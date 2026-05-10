import 'operation_status.dart';
import 'operation_type.dart';

class Operation {
  final int id;
  final int projectId;
  final int initiatorProjectParticipantId;
  final OperationType type;
  final OperationStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Operation({
    required this.id,
    required this.projectId,
    required this.initiatorProjectParticipantId,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Operation.fromJson(Map<String, dynamic> json) => Operation(
        id: json['id'] as int,
        projectId: json['project_id'] as int,
        initiatorProjectParticipantId:
            json['initiator_project_participant_id'] as int,
        type: OperationType.fromJson(json['operation_type'] as String),
        status: OperationStatus.fromJson(json['operation_status'] as String),
        createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
        updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? ''),
      );

  /// Terminal for this operation's [type] (Transfer: [rejected] is not terminal).
  bool get isTerminalForType => status.isTerminalForOperationType(type);
}
