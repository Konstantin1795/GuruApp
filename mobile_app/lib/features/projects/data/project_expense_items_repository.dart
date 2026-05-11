import '../domain/project_expense_item.dart';
import 'project_expense_items_api.dart';

class ProjectExpenseItemsRepository {
  final ProjectExpenseItemsApi _api;
  ProjectExpenseItemsRepository(this._api);

  Future<List<ProjectExpenseItemListRow>> list({
    required int companyId,
    required int projectId,
  }) async {
    final json = await _api.list(companyId: companyId, projectId: projectId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final raw = data['expense_items'] as List<dynamic>? ?? [];
    return raw.map((e) => ProjectExpenseItemListRow.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<ProjectExpenseItemDetail> getDetail({
    required int companyId,
    required int projectId,
    required int expenseItemId,
  }) async {
    final json = await _api.getDetail(
      companyId: companyId,
      projectId: projectId,
      expenseItemId: expenseItemId,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final item = (data['expense_item'] as Map).cast<String, dynamic>();
    return ProjectExpenseItemDetail.fromJson(item);
  }

  Future<ProjectExpenseItemDetail> create({
    required int companyId,
    required int projectId,
    required Map<String, dynamic> body,
  }) async {
    final json = await _api.create(companyId: companyId, projectId: projectId, body: body);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final item = (data['expense_item'] as Map).cast<String, dynamic>();
    return ProjectExpenseItemDetail.fromJson(item);
  }

  Future<ProjectExpenseItemDetail> update({
    required int companyId,
    required int projectId,
    required int expenseItemId,
    required Map<String, dynamic> body,
  }) async {
    final json = await _api.update(
      companyId: companyId,
      projectId: projectId,
      expenseItemId: expenseItemId,
      body: body,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final item = (data['expense_item'] as Map).cast<String, dynamic>();
    return ProjectExpenseItemDetail.fromJson(item);
  }

  Future<void> delete({
    required int companyId,
    required int projectId,
    required int expenseItemId,
  }) =>
      _api.delete(companyId: companyId, projectId: projectId, expenseItemId: expenseItemId);

  Future<List<ExpenseItemRecipientOption>> recipients({
    required int companyId,
    required int projectId,
    String? search,
  }) async {
    final json = await _api.recipients(
      companyId: companyId,
      projectId: projectId,
      search: search,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final raw = data['recipients'] as List<dynamic>? ?? [];
    return raw.map((e) => ExpenseItemRecipientOption.fromJson((e as Map).cast<String, dynamic>())).toList();
  }
}
