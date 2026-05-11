/// Где открыт экран проекта (ТЗ-07): company API vs personal-workspace API.
enum ProjectWorkspaceScope {
  /// `/api/company-workspace/{companyId}/...`
  company,

  /// `/api/personal-workspace/...` (в т.ч. кабинет заказчика)
  personal,
}

/// Ключ для загрузки сводки и внутренних метрик.
class ProjectWorkspaceKey {
  final int projectId;
  final int? companyId;
  final ProjectWorkspaceScope scope;

  const ProjectWorkspaceKey({
    required this.projectId,
    this.companyId,
    required this.scope,
  });

  @override
  bool operator ==(Object other) =>
      other is ProjectWorkspaceKey &&
      other.projectId == projectId &&
      other.companyId == companyId &&
      other.scope == scope;

  @override
  int get hashCode => Object.hash(projectId, companyId, scope);
}
