import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/workspaces_api.dart';
import 'data/workspaces_repository.dart';
import 'domain/workspaces.dart';

final workspacesApiProvider =
    Provider<WorkspacesApi>((ref) => WorkspacesApi(ref.watch(apiClientProvider)));

final workspacesRepositoryProvider =
    Provider<WorkspacesRepository>((ref) => WorkspacesRepository(ref.watch(workspacesApiProvider)));

/// Auto-dispose so it always fetches fresh data when the workspace entry
/// screen appears — no stale data from a previous user session.
final workspacesProvider = FutureProvider.autoDispose<Workspaces>((ref) async {
  final repo = ref.read(workspacesRepositoryProvider);
  return repo.fetch();
});

