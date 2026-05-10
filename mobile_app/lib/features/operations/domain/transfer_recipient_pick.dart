import 'transfer_target_type.dart';

/// Элемент списка получателей с GET .../transfers/recipients (ТЗ-05.2).
class TransferRecipientPick {
  final int? projectParticipantId;
  final int? counterpartyId;
  final String label;

  const TransferRecipientPick({
    required this.projectParticipantId,
    required this.counterpartyId,
    required this.label,
  });

  factory TransferRecipientPick.fromJson(Map<String, dynamic> json, TransferTargetType type) {
    int readInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    final name = (json['display_name'] as String?) ?? '';

    return switch (type) {
      TransferTargetType.accountableBalance => TransferRecipientPick(
          projectParticipantId: readInt(json['project_participant_id']),
          counterpartyId: null,
          label: name,
        ),
      TransferTargetType.personalBalance => TransferRecipientPick(
          projectParticipantId: null,
          counterpartyId: readInt(json['counterparty_id']),
          label: name,
        ),
    };
  }
}
