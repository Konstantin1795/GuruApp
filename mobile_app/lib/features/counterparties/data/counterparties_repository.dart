import '../../../core/api/api_models.dart';
import '../domain/counterparty.dart';
import 'counterparties_api.dart';

class CounterpartiesRepository {
  final CounterpartiesApi _api;
  CounterpartiesRepository(this._api);

  Future<Paginated<Counterparty>> listCompany({
    required int companyId,
    required int page,
    required int perPage,
    String? query,
    String? companyRole,
  }) async {
    final json = await _api.listCompanyCounterparties(
      companyId: companyId,
      page: page,
      perPage: perPage,
      query: query,
      companyRole: companyRole,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<Counterparty>.fromJson(data, parseItem: Counterparty.fromJson);
  }

  /// Контрагенты только с ролью заказчик (без текстового поиска `q`) — одинаковые данные везде.
  Future<List<Counterparty>> fetchCustomersOnly({
    required int companyId,
    required int page,
    required int perPage,
  }) async {
    final pageData = await listCompany(
      companyId: companyId,
      page: page,
      perPage: perPage,
      companyRole: 'CUSTOMER',
    );
    final list = pageData.items.where((c) => c.companyRole == 'CUSTOMER').toList(growable: false);
    return list;
  }

  Future<Counterparty> createCompany({
    required int companyId,
    required String companyRoleCode,
    required String fullName,
    String? email,
  }) async {
    final json = await _api.createCompanyCounterparty(
      companyId: companyId,
      companyRoleCode: companyRoleCode,
      fullName: fullName,
      email: email,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final c = (data['counterparty'] as Map).cast<String, dynamic>();
    return Counterparty.fromJson(c);
  }
}

