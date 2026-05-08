import '../../../core/api/api_client.dart';

class WorkspacesApi {
  final ApiClient _api;
  WorkspacesApi(this._api);

  Future<Map<String, dynamic>> getWorkspaces() => _api.getJson('/workspaces');

  Future<Map<String, dynamic>> createCompany({required String name}) =>
      _api.postJson('/company-workspace/companies', body: {'name': name});
}

