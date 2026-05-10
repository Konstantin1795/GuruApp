import '../../../core/api/api_models.dart';
import '../domain/personal_company_row.dart';
import 'personal_companies_api.dart';

class PersonalCompaniesRepository {
  final PersonalCompaniesApi _api;
  PersonalCompaniesRepository(this._api);

  Future<Paginated<PersonalCompanyRow>> listPage({
    required int page,
    required int perPage,
    String? workspaceRole,
  }) async {
    final json = await _api.list(page: page, perPage: perPage, workspaceRole: workspaceRole);
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<PersonalCompanyRow>.fromJson(
      data,
      parseItem: (m) => PersonalCompanyRow.fromJson(m),
    );
  }

  Future<List<PersonalCompanyRow>> listAll({String? workspaceRole, int perPage = 50}) async {
    final out = <PersonalCompanyRow>[];
    var page = 1;
    while (true) {
      final batch = await listPage(page: page, perPage: perPage, workspaceRole: workspaceRole);
      out.addAll(batch.items);
      if (!batch.pagination.hasMore) break;
      page++;
    }
    return out;
  }
}
