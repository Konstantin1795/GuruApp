class PriceListLibraryFlags {
  final bool canViewCompanyPriceListLibrary;
  final bool canCreateCompanyPriceList;
  final String? createBlockedReason;
  final int? activeOwnPriceListId;

  const PriceListLibraryFlags({
    required this.canViewCompanyPriceListLibrary,
    required this.canCreateCompanyPriceList,
    this.createBlockedReason,
    this.activeOwnPriceListId,
  });

  factory PriceListLibraryFlags.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PriceListLibraryFlags(
        canViewCompanyPriceListLibrary: true,
        canCreateCompanyPriceList: true,
      );
    }
    int? readId(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v');
    }

    return PriceListLibraryFlags(
      canViewCompanyPriceListLibrary: json['can_view_company_price_list_library'] as bool? ?? true,
      canCreateCompanyPriceList: json['can_create_company_price_list'] as bool? ?? false,
      createBlockedReason: json['company_price_list_create_blocked_reason'] as String?,
      activeOwnPriceListId: readId(json['active_own_price_list_id']),
    );
  }
}

class CompanyWorkspaceShellContext {
  final String companyRole;
  final PriceListLibraryFlags priceLists;

  const CompanyWorkspaceShellContext({
    required this.companyRole,
    required this.priceLists,
  });

  factory CompanyWorkspaceShellContext.fromJson(Map<String, dynamic> data) {
    final pl = data['price_lists'];
    final Map<String, dynamic>? plMap = pl is Map<String, dynamic>
        ? pl
        : pl is Map
            ? Map<String, dynamic>.from(pl)
            : null;
    return CompanyWorkspaceShellContext(
      companyRole: (data['company_role'] ?? '').toString(),
      priceLists: PriceListLibraryFlags.fromJson(plMap),
    );
  }
}
