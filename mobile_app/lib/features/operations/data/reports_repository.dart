import 'reports_api.dart';
import 'transfers_api.dart';

class ReportsRepository {
  final ReportsApi _api;

  ReportsRepository(this._api);

  Future<int> pendingActionCount({
    required TransferApiScope scope,
    required int companyId,
  }) async {
    final json = await _api.pendingCount(scope: scope, companyId: companyId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final v = data['pending_action_count'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
