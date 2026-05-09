import '../../../core/api/api_client.dart';

class CompanyWorkspaceApi {
  final ApiClient _api;
  CompanyWorkspaceApi(this._api);

  Future<Map<String, dynamic>> getCurrentCompany({required int companyId}) =>
      _api.getJson('/company-workspace/$companyId/companies/current');
}

