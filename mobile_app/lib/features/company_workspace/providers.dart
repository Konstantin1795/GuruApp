import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/company_workspace_api.dart';
import 'data/company_workspace_repository.dart';

final companyWorkspaceApiProvider =
    Provider<CompanyWorkspaceApi>((ref) => CompanyWorkspaceApi(ref.watch(apiClientProvider)));

final companyWorkspaceRepositoryProvider = Provider<CompanyWorkspaceRepository>(
  (ref) => CompanyWorkspaceRepository(ref.watch(companyWorkspaceApiProvider)),
);

final currentCompanyProvider = FutureProvider.family<CurrentCompany, int>((ref, companyId) async {
  final repo = ref.read(companyWorkspaceRepositoryProvider);
  return repo.fetchCurrentCompany(companyId: companyId);
});

