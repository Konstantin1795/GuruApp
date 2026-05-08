class CompanyWorkspaceItem {
  final int companyId;
  final String companyName;
  final String role;

  const CompanyWorkspaceItem({
    required this.companyId,
    required this.companyName,
    required this.role,
  });

  factory CompanyWorkspaceItem.fromJson(Map<String, dynamic> json) {
    final company = (json['company'] as Map).cast<String, dynamic>();
    return CompanyWorkspaceItem(
      companyId: company['id'] as int,
      companyName: company['name'] as String,
      role: json['role'] as String,
    );
  }
}

class PersonalWorkspaceInfo {
  final bool available;
  final List<String> roles;
  final int companiesCount;
  final int projectsCount;

  const PersonalWorkspaceInfo({
    required this.available,
    required this.roles,
    required this.companiesCount,
    required this.projectsCount,
  });

  factory PersonalWorkspaceInfo.fromJson(Map<String, dynamic> json) => PersonalWorkspaceInfo(
        available: json['available'] as bool,
        roles: (json['roles'] as List).cast<String>(),
        companiesCount: json['companies_count'] as int,
        projectsCount: json['projects_count'] as int,
      );
}

class Workspaces {
  final List<CompanyWorkspaceItem> companyWorkspaces;
  final PersonalWorkspaceInfo personalWorkspace;

  const Workspaces({
    required this.companyWorkspaces,
    required this.personalWorkspace,
  });

  factory Workspaces.fromJson(Map<String, dynamic> json) {
    final list = (json['company_workspaces'] as List).cast<Map>();
    return Workspaces(
      companyWorkspaces: list
          .map((e) => CompanyWorkspaceItem.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
      personalWorkspace: PersonalWorkspaceInfo.fromJson(
        (json['personal_workspace'] as Map).cast<String, dynamic>(),
      ),
    );
  }
}

