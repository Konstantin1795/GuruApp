import '../../../core/api/api_models.dart';
import '../domain/income_detail_view.dart';
import '../domain/income_operation.dart';
import 'incomes_api.dart';

class IncomesRepository {
  IncomesRepository(this._api);

  final IncomesApi _api;

  /// Действия заказчика ходят на personal-workspace (ТЗ-06 §20).
  static const Set<String> _personalWorkspaceActionKeys = {
    'approve_customer',
    'reject_customer',
    'return_to_customer_approval',
  };

  static const Set<String> commentRequiredKeys = {
    'reject_customer',
    'rollback_completed',
  };

  static String _actionSegment(String backendKey) => backendKey.replaceAll('_', '-');

  IncomeApiScope _scopeForAction(IncomeApiScope baseScope, String actionKey) {
    if (_personalWorkspaceActionKeys.contains(actionKey)) {
      return IncomeApiScope.personal;
    }
    return baseScope;
  }

  Future<Paginated<IncomeOperation>> list({
    required IncomeApiScope scope,
    required int companyId,
    required int projectId,
    required int page,
    required int perPage,
  }) async {
    final json = await _api.list(
      scope: scope,
      companyId: companyId,
      projectId: projectId,
      page: page,
      perPage: perPage,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<IncomeOperation>.fromJson(data, parseItem: IncomeOperation.fromJson);
  }

  Future<IncomeOperation> create({
    required IncomeApiScope scope,
    required int companyId,
    required int projectId,
    required String amount,
    String? comment,
  }) async {
    final json = await _api.create(
      scope: scope,
      companyId: companyId,
      projectId: projectId,
      amount: amount,
      comment: comment,
    );
    if (json['ok'] != true) {
      throw StateError('create income: ok != true');
    }
    final rawData = json['data'];
    if (rawData is! Map) {
      throw StateError('create income: missing data');
    }
    final data = Map<String, dynamic>.from(rawData);
    final rawIncome = data['income'];
    if (rawIncome is! Map) {
      throw StateError('create income: missing income');
    }
    return IncomeOperation.fromJson(Map<String, dynamic>.from(rawIncome));
  }

  Future<IncomeDetailView> showDetail({
    required IncomeApiScope scope,
    required int companyId,
    required int projectId,
    required int incomeId,
  }) async {
    final json = await _api.show(
      scope: scope,
      companyId: companyId,
      projectId: projectId,
      incomeId: incomeId,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return IncomeDetailView.fromShowJson(data);
  }

  Future<int> pendingActionCount({
    required IncomeApiScope scope,
    required int companyId,
  }) async {
    final json = await _api.pendingActionCount(scope: scope, companyId: companyId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final v = data['pending_action_count'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  Future<Paginated<IncomeOperation>> listHistoryAggregated({
    required IncomeApiScope scope,
    required int companyId,
    required int page,
    required int perPage,
  }) async {
    final json = await _api.listHistoryAggregated(
      scope: scope,
      companyId: companyId,
      page: page,
      perPage: perPage,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<IncomeOperation>.fromJson(data, parseItem: IncomeOperation.fromJson);
  }

  Future<IncomeOperation> performIncomeAction({
    required IncomeApiScope scope,
    required int companyId,
    required int projectId,
    required int incomeId,
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

    final json = await _api.postIncomeAction(
      scope: effectiveScope,
      companyId: companyId,
      projectId: projectId,
      incomeId: incomeId,
      actionSegment: segment,
      body: body.isEmpty ? null : body,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final income = (data['income'] as Map).cast<String, dynamic>();
    return IncomeOperation.fromJson(income);
  }
}
