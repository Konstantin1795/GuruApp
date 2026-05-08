import '../../../core/api/api_client.dart';

class ProjectsApi {
  final ApiClient _api;
  ProjectsApi(this._api);

  Future<Map<String, dynamic>> listCompanyProjects({
    required int companyId,
    required int page,
    required int perPage,
  }) =>
      _api.getJson(
        '/company-workspace/$companyId/projects',
        query: {'page': page, 'per_page': perPage},
      );

  Future<Map<String, dynamic>> listPersonalProjects({
    required int page,
    required int perPage,
  }) =>
      _api.getJson(
        '/personal-workspace/projects',
        query: {'page': page, 'per_page': perPage},
      );
}

