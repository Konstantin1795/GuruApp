import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/counterparties_api.dart';
import 'data/counterparties_repository.dart';

final counterpartiesApiProvider =
    Provider<CounterpartiesApi>((ref) => CounterpartiesApi(ref.watch(apiClientProvider)));

final counterpartiesRepositoryProvider = Provider<CounterpartiesRepository>(
  (ref) => CounterpartiesRepository(ref.watch(counterpartiesApiProvider)),
);

