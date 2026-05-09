import '../../../core/api/api_client.dart';

class CounterpartiesApi {
  final ApiClient _api;
  CounterpartiesApi(this._api);

  Future<Map<String, dynamic>> listCompanyCounterparties({
    required int companyId,
    required int page,
    required int perPage,
    String? query,
    String? companyRole,
  }) =>
      _api.getJson(
        '/company-workspace/$companyId/counterparties',
        query: {
          'page': page,
          'per_page': perPage,
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (companyRole != null && companyRole.trim().isNotEmpty)
            'company_role': companyRole.trim(),
        },
      );

  Future<Map<String, dynamic>> createCompanyCounterparty({
    required int companyId,
    required String companyRoleCode,
    required String fullName,
    String? email,
  }) =>
      _api.postJson(
        '/company-workspace/$companyId/counterparties',
        body: {
          'company_role_code': companyRoleCode,
          'full_name': fullName,
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        },
      );
}

