class ProjectParticipant {
  final int id;
  final int projectId;
  final int counterpartyId;
  final int? counterpartyUserId;
  final String? name;
  final String? email;
  final String role;
  final String level;
  final bool isActive;

  const ProjectParticipant({
    required this.id,
    required this.projectId,
    required this.counterpartyId,
    this.counterpartyUserId,
    required this.name,
    required this.email,
    required this.role,
    required this.level,
    required this.isActive,
  });

  factory ProjectParticipant.fromJson(Map<String, dynamic> json) {
    int? readUserId(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v');
    }

    int readInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    bool readBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    return ProjectParticipant(
      id: readInt(json['id']),
      projectId: readInt(json['project_id']),
      counterpartyId: readInt(json['counterparty_id']),
      counterpartyUserId: readUserId(json['counterparty_user_id']),
      name: json['name'] as String?,
      email: json['email'] as String?,
      role: (json['role'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      isActive: readBool(json['is_active']),
    );
  }

  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final e = email?.trim();
    if (e != null && e.isNotEmpty) return e;
    return 'Участник #$id';
  }
}
