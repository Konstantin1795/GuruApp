import '../../../core/api/api_models.dart';
import '../domain/project.dart';
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

  Future<Paginated<Project>> listPersonal({
    required int page,
    required int perPage,
  }) async {
    final json = await _api.listPersonalProjects(page: page, perPage: perPage);
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<Project>.fromJson(data, parseItem: Project.fromJson);
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
}

