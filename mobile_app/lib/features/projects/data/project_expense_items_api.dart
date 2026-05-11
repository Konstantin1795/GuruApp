import '../../../core/api/api_client.dart';

class ProjectExpenseItemsApi {
  final ApiClient _api;
  ProjectExpenseItemsApi(this._api);

  Future<Map<String, dynamic>> list({
    required int companyId,
    required int projectId,
  }) =>
      _api.getJson('/company-workspace/$companyId/projects/$projectId/expense-items');

  Future<Map<String, dynamic>> getDetail({
    required int companyId,
    required int projectId,
    required int expenseItemId,
  }) =>
      _api.getJson('/company-workspace/$companyId/projects/$projectId/expense-items/$expenseItemId');

  Future<Map<String, dynamic>> create({
    required int companyId,
    required int projectId,
    required Map<String, dynamic> body,
  }) =>
      _api.postJson('/company-workspace/$companyId/projects/$projectId/expense-items', body: body);

  Future<Map<String, dynamic>> update({
    required int companyId,
    required int projectId,
    required int expenseItemId,
    required Map<String, dynamic> body,
  }) =>
      _api.patchJson(
        '/company-workspace/$companyId/projects/$projectId/expense-items/$expenseItemId',
        body: body,
      );

  Future<Map<String, dynamic>> delete({
    required int companyId,
    required int projectId,
    required int expenseItemId,
  }) =>
      _api.deleteJson('/company-workspace/$companyId/projects/$projectId/expense-items/$expenseItemId');

  Future<Map<String, dynamic>> recipients({
    required int companyId,
    required int projectId,
    String? search,
  }) =>
      _api.getJson(
        '/company-workspace/$companyId/projects/$projectId/expense-items/recipients',
        query: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
}
