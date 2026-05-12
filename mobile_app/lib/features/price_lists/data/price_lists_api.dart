import '../../../core/api/api_client.dart';

class PriceListsApi {
  final ApiClient _api;
  PriceListsApi(this._api);

  Future<Map<String, dynamic>> listPriceLists({
    required int companyId,
    int page = 1,
    int perPage = 50,
    String? search,
  }) =>
      _api.getJson(
        '/company-workspace/$companyId/price-lists',
        query: {
          'page': '$page',
          'per_page': '$perPage',
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

  Future<Map<String, dynamic>> createPriceList({
    required int companyId,
    required Map<String, dynamic> body,
  }) =>
      _api.postJson('/company-workspace/$companyId/price-lists', body: body);

  Future<Map<String, dynamic>> getPriceList({
    required int companyId,
    required int priceListId,
  }) =>
      _api.getJson('/company-workspace/$companyId/price-lists/$priceListId');

  Future<Map<String, dynamic>> updatePriceList({
    required int companyId,
    required int priceListId,
    required Map<String, dynamic> body,
  }) =>
      _api.patchJson('/company-workspace/$companyId/price-lists/$priceListId', body: body);

  Future<Map<String, dynamic>> deletePriceList({
    required int companyId,
    required int priceListId,
  }) =>
      _api.deleteJson('/company-workspace/$companyId/price-lists/$priceListId');

  Future<Map<String, dynamic>> listUnits({required int companyId}) =>
      _api.getJson('/company-workspace/$companyId/units');

  Future<Map<String, dynamic>> listGroups({
    required int companyId,
    required int priceListId,
    int page = 1,
    int perPage = 50,
    String? search,
  }) =>
      _api.getJson(
        '/company-workspace/$companyId/price-lists/$priceListId/groups',
        query: {
          'page': '$page',
          'per_page': '$perPage',
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

  Future<Map<String, dynamic>> createGroup({
    required int companyId,
    required int priceListId,
    required Map<String, dynamic> body,
  }) =>
      _api.postJson('/company-workspace/$companyId/price-lists/$priceListId/groups', body: body);

  Future<Map<String, dynamic>> updateGroup({
    required int companyId,
    required int priceListId,
    required int groupId,
    required Map<String, dynamic> body,
  }) =>
      _api.patchJson(
        '/company-workspace/$companyId/price-lists/$priceListId/groups/$groupId',
        body: body,
      );

  Future<Map<String, dynamic>> deleteGroup({
    required int companyId,
    required int priceListId,
    required int groupId,
  }) =>
      _api.deleteJson('/company-workspace/$companyId/price-lists/$priceListId/groups/$groupId');

  Future<Map<String, dynamic>> listPositions({
    required int companyId,
    required int priceListId,
    required int groupId,
    int page = 1,
    int perPage = 50,
    String? search,
  }) =>
      _api.getJson(
        '/company-workspace/$companyId/price-lists/$priceListId/groups/$groupId/positions',
        query: {
          'page': '$page',
          'per_page': '$perPage',
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

  Future<Map<String, dynamic>> createPosition({
    required int companyId,
    required int priceListId,
    required int groupId,
    required Map<String, dynamic> body,
  }) =>
      _api.postJson(
        '/company-workspace/$companyId/price-lists/$priceListId/groups/$groupId/positions',
        body: body,
      );

  Future<Map<String, dynamic>> updatePosition({
    required int companyId,
    required int priceListId,
    required int groupId,
    required int positionId,
    required Map<String, dynamic> body,
  }) =>
      _api.patchJson(
        '/company-workspace/$companyId/price-lists/$priceListId/groups/$groupId/positions/$positionId',
        body: body,
      );

  Future<Map<String, dynamic>> deletePosition({
    required int companyId,
    required int priceListId,
    required int groupId,
    required int positionId,
  }) =>
      _api.deleteJson(
        '/company-workspace/$companyId/price-lists/$priceListId/groups/$groupId/positions/$positionId',
      );

  Future<Map<String, dynamic>> listProjectPriceLists({
    required int companyId,
    required int projectId,
  }) =>
      _api.getJson('/company-workspace/$companyId/projects/$projectId/price-lists');

  Future<Map<String, dynamic>> listAvailableProjectPriceLists({
    required int companyId,
    required int projectId,
  }) =>
      _api.getJson('/company-workspace/$companyId/projects/$projectId/price-lists/available');

  Future<Map<String, dynamic>> attachProjectPriceLists({
    required int companyId,
    required int projectId,
    required List<int> priceListIds,
  }) =>
      _api.postJson(
        '/company-workspace/$companyId/projects/$projectId/price-lists/attach',
        body: {'price_list_ids': priceListIds},
      );

  Future<Map<String, dynamic>> detachProjectPriceList({
    required int companyId,
    required int projectId,
    required int priceListId,
  }) =>
      _api.deleteJson('/company-workspace/$companyId/projects/$projectId/price-lists/$priceListId');
}
