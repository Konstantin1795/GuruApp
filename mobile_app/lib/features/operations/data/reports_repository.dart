import 'reports_api.dart';
import 'transfers_api.dart' show TransferApiScope;
import '../domain/report_detail_view.dart';

class ReportsRepository {
  ReportsRepository(this._api);

  final ReportsApi _api;

  /// Действия заказчика — personal-workspace (аналогично INCOME, ТЗ-06 §20).
  static const Set<String> _personalWorkspaceActionKeys = {
    'approve_customer',
    'reject_customer',
  };

  static const Set<String> commentRequiredKeys = {
    'reject_customer',
    'reject_project_head',
    'reject_supervisor',
    'rollback_completed',
  };

  static String _actionSegment(String backendKey) {
    if (backendKey == 'complete_waiting') {
      return 'complete-waiting-period';
    }
    return backendKey.replaceAll('_', '-');
  }

  TransferApiScope _scopeForAction(TransferApiScope baseScope, String actionKey) {
    if (_personalWorkspaceActionKeys.contains(actionKey)) {
      return TransferApiScope.personal;
    }
    return baseScope;
  }

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

  Future<ReportDetailView> showDetail({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int reportId,
  }) async {
    final json = await _api.show(
      scope: scope,
      companyId: companyId,
      projectId: projectId,
      reportId: reportId,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return ReportDetailView.fromShowJson(data);
  }

  Future<void> createReport({
    required int companyId,
    required int projectId,
    required Map<String, dynamic> body,
  }) async {
    final json = await _api.create(companyId: companyId, projectId: projectId, body: body);
    if (json['ok'] != true) {
      throw StateError('create report: ok != true');
    }
  }

  Future<void> performReportAction({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int reportId,
    required String actionKey,
    String? comment,
  }) async {
    if (commentRequiredKeys.contains(actionKey)) {
      final c = comment?.trim() ?? '';
      if (c.isEmpty) {
        throw ArgumentError('Комментарий обязателен для действия $actionKey');
      }
    }

    final effectiveScope = _scopeForAction(scope, actionKey);
    final segment = _actionSegment(actionKey);
    final body = <String, dynamic>{};
    if (commentRequiredKeys.contains(actionKey)) {
      body['comment'] = comment!.trim();
    }

    await _api.postReportAction(
      scope: effectiveScope,
      companyId: companyId,
      projectId: projectId,
      reportId: reportId,
      actionSegment: segment,
      body: body.isEmpty ? null : body,
    );
  }

  Future<Map<String, dynamic>> listTransferLinksRaw({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int reportId,
  }) =>
      _api.listTransferLinks(
        scope: scope,
        companyId: companyId,
        projectId: projectId,
        reportId: reportId,
      );

  Future<List<Map<String, dynamic>>> listReports({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    String? search,
  }) async {
    final json = await _api.list(
      scope: scope,
      companyId: companyId,
      projectId: projectId,
      search: search,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final raw = data['reports'] as List<dynamic>? ?? [];
    return raw.map((e) => (e as Map).cast<String, dynamic>()).toList(growable: false);
  }

  Future<void> attachTransferLinkToReport({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int reportId,
    required String operationNumber,
  }) async {
    final json = await _api.attachTransferLink(
      scope: scope,
      companyId: companyId,
      projectId: projectId,
      reportId: reportId,
      operationNumber: operationNumber,
    );
    if (json['ok'] != true) {
      throw StateError('attach transfer link: ok != true');
    }
  }
}
