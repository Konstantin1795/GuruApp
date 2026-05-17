import '../../../core/api/api_client.dart';

class CompanyWorkspaceApi {
  final ApiClient _api;
  CompanyWorkspaceApi(this._api);

  Future<Map<String, dynamic>> getCurrentCompany({required int companyId}) =>
      _api.getJson('/company-workspace/$companyId/companies/current');

  Future<Map<String, dynamic>> getWorkspaceContext({required int companyId}) =>
      _api.getJson('/company-workspace/$companyId/context');

  /// Аналитика главного экрана company-workspace (`GET …/dashboard/analytics`).
  Future<Map<String, dynamic>> getDashboardAnalytics({
    required int companyId,
    String? month,
  }) async {
    final json = await _api.getJson(
      '/company-workspace/$companyId/dashboard/analytics',
      query: month != null && month.isNotEmpty ? {'month': month} : null,
    );
    return (json['data'] as Map).cast<String, dynamic>();
  }

  /// Список операций для показателя аналитики (`GET …/dashboard/analytics/operations`).
  Future<List<Map<String, dynamic>>> getDashboardAnalyticsOperations({
    required int companyId,
    required String metric,
    String? month,
  }) async {
    final query = <String, dynamic>{'metric': metric};
    if (month != null && month.isNotEmpty) {
      query['month'] = month;
    }
    final json = await _api.getJson(
      '/company-workspace/$companyId/dashboard/analytics/operations',
      query: query,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final raw = data['items'];
    if (raw is! List) return [];
    return raw.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  /// Детализация агрегата переплаты по проекту (`GET …/dashboard/analytics/overpayment-detail`).
  Future<Map<String, dynamic>> getOverpaymentProjectDetail({
    required int companyId,
    required int projectId,
    String? month,
  }) async {
    final query = <String, dynamic>{'project_id': projectId};
    if (month != null && month.isNotEmpty) {
      query['month'] = month;
    }
    final json = await _api.getJson(
      '/company-workspace/$companyId/dashboard/analytics/overpayment-detail',
      query: query,
    );
    return (json['data'] as Map).cast<String, dynamic>();
  }
}

