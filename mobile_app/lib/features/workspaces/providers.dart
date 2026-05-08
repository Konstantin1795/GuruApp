import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/workspaces_api.dart';
import 'data/workspaces_repository.dart';

final workspacesApiProvider =
    Provider<WorkspacesApi>((ref) => WorkspacesApi(ref.watch(apiClientProvider)));

final workspacesRepositoryProvider =
    Provider<WorkspacesRepository>((ref) => WorkspacesRepository(ref.watch(workspacesApiProvider)));

