import '../../../core/api/api_client.dart';

/// ТЗ-06: те же контуры API, что и у переводов (company / personal).
enum IncomeApiScope {
  company,
  personal,
}

class IncomesApi {
  final ApiClient _api;
  IncomesApi(this._api);

  String _basePath({required IncomeApiScope scope, required int companyId, required int projectId}) {
    return switch (scope) {
      IncomeApiScope.company => '/company-workspace/$companyId/projects/$projectId/operations/incomes',
      IncomeApiScope.personal => '/personal-workspace/projects/$projectId/operations/incomes',
    };
  }

  Future<Map<String, dynamic>> list({
    required IncomeApiScope scope,
    required int companyId,
    required int projectId,
    required int page,
    required int perPage,
  }) =>
      _api.getJson(
        _basePath(scope: scope, companyId: companyId, projectId: projectId),
        query: {'page': page, 'per_page': perPage},
      );

  Future<Map<String, dynamic>> create({
    required IncomeApiScope scope,
    required int companyId,
    required int projectId,
    required String amount,
    String? comment,
  }) async {
    final body = <String, dynamic>{'amount': amount};
    if (comment != null && comment.trim().isNotEmpty) {
      body['comment'] = comment.trim();
    }
    return _api.postJson(
      _basePath(scope: scope, companyId: companyId, projectId: projectId),
      body: body,
    );
  }

  Future<Map<String, dynamic>> show({
    required IncomeApiScope scope,
    required int companyId,
    required int projectId,
    required int incomeId,
  }) =>
      _api.getJson(
        '${_basePath(scope: scope, companyId: companyId, projectId: projectId)}/$incomeId',
      );

  String _aggregatedHistoryPath({required IncomeApiScope scope, required int companyId}) {
    return switch (scope) {
      IncomeApiScope.company => '/company-workspace/$companyId/operations/incomes/history',
      IncomeApiScope.personal => '/personal-workspace/operations/incomes/history',
    };
  }

  String _pendingCountPath({required IncomeApiScope scope, required int companyId}) {
    return switch (scope) {
      IncomeApiScope.company => '/company-workspace/$companyId/operations/incomes/pending-count',
      IncomeApiScope.personal => '/personal-workspace/operations/incomes/pending-count',
    };
  }

  Future<Map<String, dynamic>> listHistoryAggregated({
    required IncomeApiScope scope,
    required int companyId,
    required int page,
    required int perPage,
  }) =>
      _api.getJson(
        _aggregatedHistoryPath(scope: scope, companyId: companyId),
        query: {'page': page, 'per_page': perPage},
      );

  Future<Map<String, dynamic>> pendingActionCount({
    required IncomeApiScope scope,
    required int companyId,
  }) =>
      _api.getJson(_pendingCountPath(scope: scope, companyId: companyId));

  Future<Map<String, dynamic>> patchIncome({
    required IncomeApiScope scope,
    required int companyId,
    required int projectId,
    required int incomeId,
    required String amount,
    String? comment,
  }) async {
    final body = <String, dynamic>{'amount': amount};
    if (comment != null) {
      body['comment'] = comment;
    }
    return _api.patchJson(
      '${_basePath(scope: scope, companyId: companyId, projectId: projectId)}/$incomeId',
      body: body,
    );
  }

  Future<Map<String, dynamic>> postIncomeAction({
    required IncomeApiScope scope,
    required int companyId,
    required int projectId,
    required int incomeId,
    required String actionSegment,
    Map<String, dynamic>? body,
  }) =>
      _api.postJson(
        '${_basePath(scope: scope, companyId: companyId, projectId: projectId)}/$incomeId/$actionSegment',
        body: body,
      );
}
