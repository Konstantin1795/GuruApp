import '../../../core/api/api_client.dart';

class CounterpartiesApi {
  final ApiClient _api;
  CounterpartiesApi(this._api);

  Future<Map<String, dynamic>> listCompanyCounterparties({
    required int companyId,
    required int page,
    required int perPage,
  }) =>
      _api.getJson(
        '/company-workspace/$companyId/counterparties',
        query: {'page': page, 'per_page': perPage},
      );
}

