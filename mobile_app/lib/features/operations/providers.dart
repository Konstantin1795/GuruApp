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
