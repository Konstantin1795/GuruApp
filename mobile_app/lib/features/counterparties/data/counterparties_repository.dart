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
  }) async {
    final json = await _api.listCompanyCounterparties(
      companyId: companyId,
      page: page,
      perPage: perPage,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<Counterparty>.fromJson(data, parseItem: Counterparty.fromJson);
  }
}

