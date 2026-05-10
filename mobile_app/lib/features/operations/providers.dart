import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/transfers_api.dart';
import 'data/transfers_repository.dart';

final transfersApiProvider = Provider<TransfersApi>(
  (ref) => TransfersApi(ref.watch(apiClientProvider)),
);

final transfersRepositoryProvider = Provider<TransfersRepository>(
  (ref) => TransfersRepository(ref.watch(transfersApiProvider)),
);

typedef TransferPendingKey = ({TransferApiScope scope, int companyId});

final transferPendingActionCountProvider =
    FutureProvider.autoDispose.family<int, TransferPendingKey>(
  (ref, key) async {
    return ref.read(transfersRepositoryProvider).pendingActionCount(
          scope: key.scope,
          companyId: key.companyId,
        );
  },
);
