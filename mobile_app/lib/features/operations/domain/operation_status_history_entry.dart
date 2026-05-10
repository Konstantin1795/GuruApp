class OperationStatusHistoryEntry {
  final int id;
  final String? fromStatus;
  final String toStatus;
  final String? comment;
  final int? authorUserId;
  final String? authorFullName;
  final DateTime? createdAt;

  const OperationStatusHistoryEntry({
    required this.id,
    required this.fromStatus,
    required this.toStatus,
    required this.comment,
    required this.authorUserId,
    required this.authorFullName,
    required this.createdAt,
  });

  factory OperationStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return OperationStatusHistoryEntry(
      id: readInt(json['id']),
      fromStatus: json['from_status'] as String?,
      toStatus: (json['to_status'] ?? '').toString(),
      comment: json['comment'] as String?,
      authorUserId: json['author_user_id'] == null ? null : readInt(json['author_user_id']),
      authorFullName: json['author_full_name'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
