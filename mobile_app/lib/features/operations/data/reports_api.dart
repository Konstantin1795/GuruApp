import '../../../core/api/api_client.dart';
import 'transfers_api.dart';

class ReportsApi {
  final ApiClient _client;

  ReportsApi(this._client);

  Future<Map<String, dynamic>> pendingCount({
    required TransferApiScope scope,
    required int companyId,
  }) async {
    final path = scope == TransferApiScope.company
        ? '/company-workspace/$companyId/operations/reports/pending-count'
        : '/personal-workspace/operations/reports/pending-count';
    return _client.getJson(path);
  }
}
