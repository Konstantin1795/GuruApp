import '../../../core/api/api_models.dart';
import 'price_lists_api.dart';

class PriceListListRow {
  final int id;
  final String name;
  final String creatorDisplayName;
  final int groupsCount;
  final int positionsCount;

  const PriceListListRow({
    required this.id,
    required this.name,
    required this.creatorDisplayName,
    required this.groupsCount,
    required this.positionsCount,
  });

  factory PriceListListRow.fromJson(Map<String, dynamic> json) => PriceListListRow(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '').toString(),
        creatorDisplayName: (json['creator_display_name'] ?? '').toString(),
        groupsCount: (json['groups_count'] as num?)?.toInt() ?? 0,
        positionsCount: (json['positions_count'] as num?)?.toInt() ?? 0,
      );
}

class PriceListGroupSummary {
  final int id;
  final String name;
  final int sortOrder;
  final int positionsCount;

  const PriceListGroupSummary({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.positionsCount,
  });

  factory PriceListGroupSummary.fromJson(Map<String, dynamic> json) => PriceListGroupSummary(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '').toString(),
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        positionsCount: (json['positions_count'] as num?)?.toInt() ?? 0,
      );
}

class UnitRow {
  final int id;
  final String name;
  final String shortName;

  const UnitRow({required this.id, required this.name, required this.shortName});

  factory UnitRow.fromJson(Map<String, dynamic> json) => UnitRow(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '').toString(),
        shortName: (json['short_name'] ?? '').toString(),
      );
}

class PriceListPositionRow {
  final int id;
  final String serviceName;
  final UnitRow? unit;
  final String recipientUnitPrice;
  final String customerUnitPrice;
  final String profitAmount;
  final String? profitPercent;
  final int sortOrder;

  const PriceListPositionRow({
    required this.id,
    required this.serviceName,
    this.unit,
    required this.recipientUnitPrice,
    required this.customerUnitPrice,
    required this.profitAmount,
    this.profitPercent,
    required this.sortOrder,
  });

  factory PriceListPositionRow.fromJson(Map<String, dynamic> json) {
    final u = json['unit'];
    return PriceListPositionRow(
      id: (json['id'] as num).toInt(),
      serviceName: (json['service_name'] ?? '').toString(),
      unit: u is Map<String, dynamic>
          ? UnitRow.fromJson(u)
          : u is Map
              ? UnitRow.fromJson(Map<String, dynamic>.from(u))
              : null,
      recipientUnitPrice: (json['recipient_unit_price'] ?? '0').toString(),
      customerUnitPrice: (json['customer_unit_price'] ?? '0').toString(),
      profitAmount: (json['profit_amount'] ?? '0').toString(),
      profitPercent: json['profit_percent']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class PriceListDetail {
  final int id;
  final String name;
  final bool isActive;
  final String creatorDisplayName;
  final int createdByCounterpartyId;
  final bool canEdit;
  final List<PriceListGroupSummary> groups;

  const PriceListDetail({
    required this.id,
    required this.name,
    required this.isActive,
    required this.creatorDisplayName,
    required this.createdByCounterpartyId,
    required this.canEdit,
    required this.groups,
  });

  factory PriceListDetail.fromJson(Map<String, dynamic> json) {
    final groupsRaw = json['groups'];
    final groups = <PriceListGroupSummary>[];
    if (groupsRaw is List) {
      for (final g in groupsRaw) {
        if (g is Map) {
          groups.add(PriceListGroupSummary.fromJson(g.cast<String, dynamic>()));
        }
      }
    }
    return PriceListDetail(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      isActive: json['is_active'] as bool? ?? true,
      creatorDisplayName: (json['creator_display_name'] ?? '').toString(),
      createdByCounterpartyId: (json['created_by_counterparty_id'] as num?)?.toInt() ?? 0,
      canEdit: json['can_edit'] as bool? ?? false,
      groups: groups,
    );
  }
}

class PriceListGroupRow {
  final int id;
  final String name;
  final int sortOrder;

  const PriceListGroupRow({required this.id, required this.name, required this.sortOrder});

  factory PriceListGroupRow.fromJson(Map<String, dynamic> json) => PriceListGroupRow(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '').toString(),
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class ProjectAttachedPriceList {
  final int rowId;
  final int priceListId;
  final String name;
  final bool isActive;
  final String? deletedAt;
  final String creatorDisplayName;

  const ProjectAttachedPriceList({
    required this.rowId,
    required this.priceListId,
    required this.name,
    required this.isActive,
    this.deletedAt,
    required this.creatorDisplayName,
  });

  factory ProjectAttachedPriceList.fromJson(Map<String, dynamic> json) {
    final pl = (json['price_list'] as Map?)?.cast<String, dynamic>();
    return ProjectAttachedPriceList(
      rowId: (json['id'] as num).toInt(),
      priceListId: (pl?['id'] as num?)?.toInt() ?? 0,
      name: (pl?['name'] ?? '').toString(),
      isActive: pl?['is_active'] as bool? ?? true,
      deletedAt: pl?['deleted_at'] as String?,
      creatorDisplayName: (pl?['creator_display_name'] ?? '').toString(),
    );
  }
}

class AvailablePriceListPick {
  final int id;
  final String name;
  final String creatorDisplayName;

  const AvailablePriceListPick({
    required this.id,
    required this.name,
    required this.creatorDisplayName,
  });

  factory AvailablePriceListPick.fromJson(Map<String, dynamic> json) => AvailablePriceListPick(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '').toString(),
        creatorDisplayName: (json['creator_display_name'] ?? '').toString(),
      );
}

class PriceListsRepository {
  final PriceListsApi _api;
  PriceListsRepository(this._api);

  Future<Paginated<PriceListListRow>> listPriceLists({
    required int companyId,
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    final json = await _api.listPriceLists(companyId: companyId, page: page, perPage: perPage, search: search);
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<PriceListListRow>.fromJson(
      data,
      parseItem: (m) => PriceListListRow.fromJson(m.cast<String, dynamic>()),
    );
  }

  Future<PriceListDetail> getPriceList({required int companyId, required int priceListId}) async {
    final json = await _api.getPriceList(companyId: companyId, priceListId: priceListId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final pl = (data['price_list'] as Map).cast<String, dynamic>();
    return PriceListDetail.fromJson(pl);
  }

  Future<void> createPriceList({required int companyId, required String name}) async {
    await _api.createPriceList(companyId: companyId, body: {'name': name});
  }

  Future<void> updatePriceList({required int companyId, required int priceListId, required String name}) async {
    await _api.updatePriceList(companyId: companyId, priceListId: priceListId, body: {'name': name});
  }

  Future<Map<String, dynamic>> deletePriceList({required int companyId, required int priceListId}) async {
    final json = await _api.deletePriceList(companyId: companyId, priceListId: priceListId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    return data;
  }

  Future<List<UnitRow>> listUnits({required int companyId}) async {
    final json = await _api.listUnits(companyId: companyId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final list = data['units'] as List<dynamic>? ?? [];
    return list
        .whereType<Map>()
        .map((m) => UnitRow.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<Paginated<PriceListGroupRow>> listGroups({
    required int companyId,
    required int priceListId,
    int page = 1,
    String? search,
  }) async {
    final json = await _api.listGroups(
      companyId: companyId,
      priceListId: priceListId,
      page: page,
      perPage: 50,
      search: search,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<PriceListGroupRow>.fromJson(
      data,
      parseItem: (m) => PriceListGroupRow.fromJson(m.cast<String, dynamic>()),
    );
  }

  Future<void> createGroup({
    required int companyId,
    required int priceListId,
    required String name,
  }) async {
    await _api.createGroup(companyId: companyId, priceListId: priceListId, body: {'name': name});
  }

  Future<void> updateGroup({
    required int companyId,
    required int priceListId,
    required int groupId,
    required String name,
  }) async {
    await _api.updateGroup(
      companyId: companyId,
      priceListId: priceListId,
      groupId: groupId,
      body: {'name': name},
    );
  }

  Future<void> deleteGroup({
    required int companyId,
    required int priceListId,
    required int groupId,
  }) async {
    await _api.deleteGroup(companyId: companyId, priceListId: priceListId, groupId: groupId);
  }

  Future<Paginated<PriceListPositionRow>> listPositions({
    required int companyId,
    required int priceListId,
    required int groupId,
    int page = 1,
    String? search,
  }) async {
    final json = await _api.listPositions(
      companyId: companyId,
      priceListId: priceListId,
      groupId: groupId,
      page: page,
      perPage: 50,
      search: search,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<PriceListPositionRow>.fromJson(
      data,
      parseItem: (m) => PriceListPositionRow.fromJson(m.cast<String, dynamic>()),
    );
  }

  Future<void> createPosition({
    required int companyId,
    required int priceListId,
    required int groupId,
    required String serviceName,
    required int unitId,
    required String recipientUnitPrice,
    required String customerUnitPrice,
  }) async {
    await _api.createPosition(
      companyId: companyId,
      priceListId: priceListId,
      groupId: groupId,
      body: {
        'service_name': serviceName,
        'unit_id': unitId,
        'recipient_unit_price': recipientUnitPrice,
        'customer_unit_price': customerUnitPrice,
      },
    );
  }

  Future<void> updatePosition({
    required int companyId,
    required int priceListId,
    required int groupId,
    required int positionId,
    required Map<String, dynamic> body,
  }) async {
    await _api.updatePosition(
      companyId: companyId,
      priceListId: priceListId,
      groupId: groupId,
      positionId: positionId,
      body: body,
    );
  }

  Future<void> deletePosition({
    required int companyId,
    required int priceListId,
    required int groupId,
    required int positionId,
  }) async {
    await _api.deletePosition(
      companyId: companyId,
      priceListId: priceListId,
      groupId: groupId,
      positionId: positionId,
    );
  }

  Future<List<ProjectAttachedPriceList>> listProjectPriceLists({
    required int companyId,
    required int projectId,
  }) async {
    final json = await _api.listProjectPriceLists(companyId: companyId, projectId: projectId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final list = data['project_price_lists'] as List<dynamic>? ?? [];
    return list
        .whereType<Map>()
        .map((m) => ProjectAttachedPriceList.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<List<AvailablePriceListPick>> listAvailableForProject({
    required int companyId,
    required int projectId,
  }) async {
    final json = await _api.listAvailableProjectPriceLists(companyId: companyId, projectId: projectId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final list = data['price_lists'] as List<dynamic>? ?? [];
    return list
        .whereType<Map>()
        .map((m) => AvailablePriceListPick.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<List<int>> attachToProject({
    required int companyId,
    required int projectId,
    required List<int> priceListIds,
  }) async {
    final json = await _api.attachProjectPriceLists(
      companyId: companyId,
      projectId: projectId,
      priceListIds: priceListIds,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final raw = data['attached_price_list_ids'] as List<dynamic>? ?? [];
    return raw.map((e) => (e as num).toInt()).toList();
  }

  Future<void> detachFromProject({
    required int companyId,
    required int projectId,
    required int priceListId,
  }) async {
    await _api.detachProjectPriceList(companyId: companyId, projectId: projectId, priceListId: priceListId);
  }
}
