import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/participant_wallet_api.dart';
import 'data/participant_wallet_repository.dart';
import 'data/project_participants_api.dart';
import 'data/project_participants_repository.dart';
import 'data/projects_api.dart';
import 'data/projects_repository.dart';

final projectsApiProvider = Provider<ProjectsApi>((ref) => ProjectsApi(ref.watch(apiClientProvider)));

final projectsRepositoryProvider =
    Provider<ProjectsRepository>((ref) => ProjectsRepository(ref.watch(projectsApiProvider)));

final projectParticipantsApiProvider = Provider<ProjectParticipantsApi>(
  (ref) => ProjectParticipantsApi(ref.watch(apiClientProvider)),
);

final projectParticipantsRepositoryProvider = Provider<ProjectParticipantsRepository>(
  (ref) => ProjectParticipantsRepository(ref.watch(projectParticipantsApiProvider)),
);

final participantWalletApiProvider = Provider<ParticipantWalletApi>(
  (ref) => ParticipantWalletApi(ref.watch(apiClientProvider)),
);

final participantWalletRepositoryProvider = Provider<ParticipantWalletRepository>(
  (ref) => ParticipantWalletRepository(ref.watch(participantWalletApiProvider)),
);

