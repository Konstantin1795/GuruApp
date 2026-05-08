import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/projects_api.dart';
import 'data/projects_repository.dart';

final projectsApiProvider = Provider<ProjectsApi>((ref) => ProjectsApi(ref.watch(apiClientProvider)));

final projectsRepositoryProvider =
    Provider<ProjectsRepository>((ref) => ProjectsRepository(ref.watch(projectsApiProvider)));

