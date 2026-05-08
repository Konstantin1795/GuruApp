class Project {
  final int id;
  final int companyId;
  final String name;
  final int progressPercent;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Project({
    required this.id,
    required this.companyId,
    required this.name,
    required this.progressPercent,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as int,
        companyId: json['company_id'] as int,
        name: json['name'] as String,
        progressPercent: (json['progress_percent'] as num).toInt(),
        isActive: json['is_active'] as bool,
        createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
        updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? ''),
      );
}

