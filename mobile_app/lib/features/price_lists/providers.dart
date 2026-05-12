import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_models.dart';
import '../../../core/providers.dart';
import 'data/price_lists_api.dart';
import 'data/price_lists_repository.dart';

final priceListsApiProvider = Provider<PriceListsApi>((ref) => PriceListsApi(ref.watch(apiClientProvider)));

final priceListsRepositoryProvider =
    Provider<PriceListsRepository>((ref) => PriceListsRepository(ref.watch(priceListsApiProvider)));

typedef CompanyPriceListsKey = ({int companyId, String search});

final companyPriceListsProvider =
    FutureProvider.autoDispose.family<Paginated<PriceListListRow>, CompanyPriceListsKey>((ref, key) async {
  return ref.read(priceListsRepositoryProvider).listPriceLists(
        companyId: key.companyId,
        page: 1,
        search: key.search.trim().isEmpty ? null : key.search.trim(),
      );
});

typedef PriceListDetailKey = ({int companyId, int priceListId});

final priceListDetailProvider =
    FutureProvider.autoDispose.family<PriceListDetail, PriceListDetailKey>((ref, key) async {
  return ref.read(priceListsRepositoryProvider).getPriceList(
        companyId: key.companyId,
        priceListId: key.priceListId,
      );
});

final unitsListProvider = FutureProvider.autoDispose.family<List<UnitRow>, int>((ref, companyId) async {
  return ref.read(priceListsRepositoryProvider).listUnits(companyId: companyId);
});

typedef PriceListGroupsKey = ({int companyId, int priceListId, String search});

final priceListGroupsProvider =
    FutureProvider.autoDispose.family<Paginated<PriceListGroupRow>, PriceListGroupsKey>((ref, key) async {
  return ref.read(priceListsRepositoryProvider).listGroups(
        companyId: key.companyId,
        priceListId: key.priceListId,
        search: key.search.trim().isEmpty ? null : key.search.trim(),
      );
});

typedef PriceListPositionsKey = ({int companyId, int priceListId, int groupId, String search});

final priceListPositionsProvider =
    FutureProvider.autoDispose.family<Paginated<PriceListPositionRow>, PriceListPositionsKey>((ref, key) async {
  return ref.read(priceListsRepositoryProvider).listPositions(
        companyId: key.companyId,
        priceListId: key.priceListId,
        groupId: key.groupId,
        search: key.search.trim().isEmpty ? null : key.search.trim(),
      );
});

typedef ProjectPriceListsKey = ({int companyId, int projectId});

final projectPriceListsProvider =
    FutureProvider.autoDispose.family<List<ProjectAttachedPriceList>, ProjectPriceListsKey>((ref, key) async {
  return ref.read(priceListsRepositoryProvider).listProjectPriceLists(
        companyId: key.companyId,
        projectId: key.projectId,
      );
});

final availableProjectPriceListsProvider =
    FutureProvider.autoDispose.family<List<AvailablePriceListPick>, ProjectPriceListsKey>((ref, key) async {
  return ref.read(priceListsRepositoryProvider).listAvailableForProject(
        companyId: key.companyId,
        projectId: key.projectId,
      );
});
