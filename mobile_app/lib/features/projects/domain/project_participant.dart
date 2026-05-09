class ProjectParticipant {
  final int id;
  final int projectId;
  final int counterpartyId;
  final String? name;
  final String? email;
  final String role;
  final String level;
  final bool isActive;

  const ProjectParticipant({
    required this.id,
    required this.projectId,
    required this.counterpartyId,
    required this.name,
    required this.email,
    required this.role,
    required this.level,
    required this.isActive,
  });

  factory ProjectParticipant.fromJson(Map<String, dynamic> json) => ProjectParticipant(
        id: json['id'] as int,
        projectId: json['project_id'] as int,
        counterpartyId: json['counterparty_id'] as int,
        name: json['name'] as String?,
        email: json['email'] as String?,
        role: json['role'] as String,
        level: json['level'] as String,
        isActive: json['is_active'] as bool,
      );

  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final e = email?.trim();
    if (e != null && e.isNotEmpty) return e;
    return 'Участник #$id';
  }
}
