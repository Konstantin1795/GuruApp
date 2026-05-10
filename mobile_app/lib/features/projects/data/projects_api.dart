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

  Future<Map<String, dynamic>> createCompanyProject({
    required int companyId,
    required String name,
    int? customerCounterpartyId,
  }) =>
      _api.postJson(
        '/company-workspace/$companyId/projects',
        body: {
          'name': name,
          if (customerCounterpartyId != null) ...{
            'customer_counterparty_id': customerCounterpartyId,
          },
        },
      );

  Future<Map<String, dynamic>> listPersonalProjects({
    required int page,
    required int perPage,
    String? workspaceRole,
  }) {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (workspaceRole != null) {
      query['workspace_role'] = workspaceRole;
    }
    return _api.getJson('/personal-workspace/projects', query: query);
  }
}
