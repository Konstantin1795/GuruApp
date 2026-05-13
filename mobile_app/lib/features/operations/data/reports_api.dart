import '../../../core/api/api_client.dart';
import 'transfers_api.dart' show TransferApiScope;

class ReportsApi {
  final ApiClient _client;

  ReportsApi(this._client);

  String _basePath({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
  }) {
    return switch (scope) {
      TransferApiScope.company =>
        '/company-workspace/$companyId/projects/$projectId/operations/reports',
      TransferApiScope.personal => '/personal-workspace/projects/$projectId/operations/reports',
    };
  }

  Future<Map<String, dynamic>> pendingCount({
    required TransferApiScope scope,
    required int companyId,
  }) async {
    final path = scope == TransferApiScope.company
        ? '/company-workspace/$companyId/operations/reports/pending-count'
        : '/personal-workspace/operations/reports/pending-count';
    return _client.getJson(path);
  }

  Future<Map<String, dynamic>> list({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    String? search,
  }) {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    return _client.getJson(
      _basePath(scope: scope, companyId: companyId, projectId: projectId),
      query: query.isEmpty ? null : query,
    );
  }

  Future<Map<String, dynamic>> show({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int reportId,
  }) =>
      _client.getJson(
        '${_basePath(scope: scope, companyId: companyId, projectId: projectId)}/$reportId',
      );

  Future<Map<String, dynamic>> create({
    required int companyId,
    required int projectId,
    required Map<String, dynamic> body,
  }) =>
      _client.postJson(
        _basePath(scope: TransferApiScope.company, companyId: companyId, projectId: projectId),
        body: body,
      );

  Future<Map<String, dynamic>> postReportAction({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int reportId,
    required String actionSegment,
    Map<String, dynamic>? body,
  }) =>
      _client.postJson(
        '${_basePath(scope: scope, companyId: companyId, projectId: projectId)}/$reportId/$actionSegment',
        body: body,
      );

  Future<Map<String, dynamic>> listTransferLinks({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int reportId,
  }) =>
      _client.getJson(
        '${_basePath(scope: scope, companyId: companyId, projectId: projectId)}/$reportId/transfer-links',
      );

  Future<Map<String, dynamic>> attachTransferLink({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int reportId,
    required String operationNumber,
  }) =>
      _client.postJson(
        '${_basePath(scope: scope, companyId: companyId, projectId: projectId)}/$reportId/transfer-links',
        body: {'operation_number': operationNumber.trim()},
      );
}
