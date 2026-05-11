import '../../../core/api/api_models.dart';
import '../../customer_workspace/domain/personal_workspace_project_row.dart';
import '../domain/project.dart';
import '../domain/project_internal_metrics.dart';
import '../domain/project_summary.dart';
import '../domain/project_workspace_scope.dart';
import 'projects_api.dart';

class ProjectsRepository {
  final ProjectsApi _api;
  ProjectsRepository(this._api);

  Future<Paginated<Project>> listCompany({
    required int companyId,
    required int page,
    required int perPage,
  }) async {
    final json = await _api.listCompanyProjects(companyId: companyId, page: page, perPage: perPage);
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<Project>.fromJson(data, parseItem: Project.fromJson);
  }

  Future<List<Project>> listAllCompany({
    required int companyId,
    int perPage = 50,
  }) async {
    final out = <Project>[];
    var page = 1;
    while (true) {
      final batch = await listCompany(
        companyId: companyId,
        page: page,
        perPage: perPage,
      );
      out.addAll(batch.items);
      if (!batch.pagination.hasMore) break;
      page++;
    }
    return out;
  }

  Future<Paginated<Project>> listPersonal({
    required int page,
    required int perPage,
  }) async {
    final json = await _api.listPersonalProjects(page: page, perPage: perPage);
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<Project>.fromJson(data, parseItem: _projectFromPersonalPayload);
  }

  Future<Paginated<PersonalWorkspaceProjectRow>> listPersonalWorkspaceRows({
    required int page,
    required int perPage,
    String? workspaceRole,
  }) async {
    final json = await _api.listPersonalProjects(
      page: page,
      perPage: perPage,
      workspaceRole: workspaceRole,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<PersonalWorkspaceProjectRow>.fromJson(
      data,
      parseItem: PersonalWorkspaceProjectRow.fromJson,
    );
  }

  Future<List<PersonalWorkspaceProjectRow>> listAllPersonalWorkspaceRows({
    String? workspaceRole,
    int perPage = 50,
  }) async {
    final out = <PersonalWorkspaceProjectRow>[];
    var page = 1;
    while (true) {
      final batch = await listPersonalWorkspaceRows(
        page: page,
        perPage: perPage,
        workspaceRole: workspaceRole,
      );
      out.addAll(batch.items);
      if (!batch.pagination.hasMore) break;
      page++;
    }
    return out;
  }

  Future<Project> createCompany({
    required int companyId,
    required String name,
    int? customerCounterpartyId,
  }) async {
    final json = await _api.createCompanyProject(
      companyId: companyId,
      name: name,
      customerCounterpartyId: customerCounterpartyId,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final p = (data['project'] as Map).cast<String, dynamic>();
    return Project.fromJson(p);
  }

  Future<ProjectSummary> getProjectSummary(ProjectWorkspaceKey key) async {
    final Map<String, dynamic> json;
    switch (key.scope) {
      case ProjectWorkspaceScope.company:
        json = await _api.getProjectSummaryCompany(
          companyId: key.companyId!,
          projectId: key.projectId,
        );
      case ProjectWorkspaceScope.personal:
        json = await _api.getProjectSummaryPersonal(projectId: key.projectId);
    }
    final data = (json['data'] as Map).cast<String, dynamic>();
    return ProjectSummary.fromJson(data);
  }

  Future<ProjectInternalMetrics> getProjectInternalMetrics(ProjectWorkspaceKey key) async {
    final Map<String, dynamic> json;
    switch (key.scope) {
      case ProjectWorkspaceScope.company:
        json = await _api.getProjectInternalMetricsCompany(
          companyId: key.companyId!,
          projectId: key.projectId,
        );
      case ProjectWorkspaceScope.personal:
        json = await _api.getProjectInternalMetricsPersonal(projectId: key.projectId);
    }
    final data = (json['data'] as Map).cast<String, dynamic>();
    return ProjectInternalMetrics.fromJson(data);
  }
}

/// Builds a flat [Project] from nested personal-workspace payload.
Project _projectFromPersonalPayload(Map<String, dynamic> json) {
  final p = (json['project'] as Map).cast<String, dynamic>();
  final c = (json['company'] as Map).cast<String, dynamic>();
  return Project(
    id: p['id'] as int,
    companyId: c['id'] as int,
    name: p['name'] as String,
    progressPercent: (p['progress_percent'] as num).toInt(),
    isActive: p['is_active'] as bool,
    createdAt: null,
    updatedAt: null,
  );
}
