import '../../../core/api/api_client.dart';

class PersonalCompaniesApi {
  final ApiClient _api;
  PersonalCompaniesApi(this._api);

  Future<Map<String, dynamic>> list({
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
    return _api.getJson('/personal-workspace/companies', query: query);
  }
}
