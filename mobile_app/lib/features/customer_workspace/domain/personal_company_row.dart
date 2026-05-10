class PersonalCompanyRow {
  final int id;
  final String name;
  final bool isActive;
  final String companyRole;
  final int projectsCount;

  const PersonalCompanyRow({
    required this.id,
    required this.name,
    required this.isActive,
    required this.companyRole,
    required this.projectsCount,
  });

  /// Fills [name] from [fallback] when API returned an empty name.
  PersonalCompanyRow withFallbackName(String? fallback) {
    if (name.trim().isNotEmpty) return this;
    final f = fallback?.trim() ?? '';
    if (f.isEmpty) return this;
    return PersonalCompanyRow(
      id: id,
      name: f,
      isActive: isActive,
      companyRole: companyRole,
      projectsCount: projectsCount,
    );
  }

  factory PersonalCompanyRow.fromJson(Map<String, dynamic> json) {
    final companyRaw = json['company'];
    final companyMap = companyRaw is Map
        ? companyRaw.cast<String, dynamic>()
        : <String, dynamic>{};

    int asInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    bool asBool(Object? v) {
      if (v is bool) return v;
      if (v == 1 || v == '1' || v == 'true') return true;
      return false;
    }

    String readName() {
      for (final key in ['name', 'company_name']) {
        final v = companyMap[key] ?? json[key];
        if (v != null) {
          final s = v.toString().trim();
          if (s.isNotEmpty) return s;
        }
      }
      return '';
    }

    return PersonalCompanyRow(
      id: asInt(companyMap['id'] ?? json['company_id']),
      name: readName(),
      isActive: asBool(companyMap['is_active'] ?? json['is_active']),
      companyRole: (json['company_role'] ?? companyMap['company_role_code'] ?? '').toString(),
      projectsCount: asInt(json['projects_count'] ?? companyMap['projects_count']),
    );
  }
}
