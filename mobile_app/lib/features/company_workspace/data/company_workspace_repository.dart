import '../domain/company_workspace_context.dart';
import 'company_workspace_api.dart';

class CurrentCompany {
  final int id;
  final String name;
  final bool isActive;
  final String? myCompanyRoleCode;

  const CurrentCompany({
    required this.id,
    required this.name,
    required this.isActive,
    this.myCompanyRoleCode,
  });

  factory CurrentCompany.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    bool readBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    return CurrentCompany(
      id: readInt(json['id']),
      name: (json['name'] ?? '').toString(),
      isActive: readBool(json['is_active']),
    );
  }
}

class CompanyWorkspaceRepository {
  final CompanyWorkspaceApi _api;
  CompanyWorkspaceRepository(this._api);

  Future<CurrentCompany> fetchCurrentCompany({required int companyId}) async {
    final json = await _api.getCurrentCompany(companyId: companyId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final company = (data['company'] as Map).cast<String, dynamic>();
    final role = data['my_company_role']?.toString();
    final parsed = CurrentCompany.fromJson(company);
    return CurrentCompany(
      id: parsed.id,
      name: parsed.name,
      isActive: parsed.isActive,
      myCompanyRoleCode: role,
    );
  }

  Future<CompanyWorkspaceShellContext> fetchShellContext({required int companyId}) async {
    final json = await _api.getWorkspaceContext(companyId: companyId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    return CompanyWorkspaceShellContext.fromJson(data);
  }
}

