import 'company_workspace_api.dart';

class CurrentCompany {
  final int id;
  final String name;
  final bool isActive;

  const CurrentCompany({required this.id, required this.name, required this.isActive});

  factory CurrentCompany.fromJson(Map<String, dynamic> json) => CurrentCompany(
        id: json['id'] as int,
        name: json['name'] as String,
        isActive: json['is_active'] as bool,
      );
}

class CompanyWorkspaceRepository {
  final CompanyWorkspaceApi _api;
  CompanyWorkspaceRepository(this._api);

  Future<CurrentCompany> fetchCurrentCompany({required int companyId}) async {
    final json = await _api.getCurrentCompany(companyId: companyId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final company = (data['company'] as Map).cast<String, dynamic>();
    return CurrentCompany.fromJson(company);
  }
}

