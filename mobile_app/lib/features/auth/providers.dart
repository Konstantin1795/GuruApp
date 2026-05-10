import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/auth_api.dart';
import 'data/auth_repository.dart';
import 'domain/user.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(ref.watch(authApiProvider), ref.watch(tokenStorageProvider)),
);

/// Cached `/auth/me` for headers and profile hints. Invalidate on login/logout.
final currentUserProvider = FutureProvider.autoDispose<User>(
  (ref) => ref.watch(authRepositoryProvider).me(),
);

