import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/incomes_api.dart';
import 'data/incomes_repository.dart';
import 'data/reports_api.dart';
import 'data/reports_repository.dart';
import 'data/transfers_api.dart';
import 'data/transfers_repository.dart';

final transfersApiProvider = Provider<TransfersApi>(
  (ref) => TransfersApi(ref.watch(apiClientProvider)),
);

final transfersRepositoryProvider = Provider<TransfersRepository>(
  (ref) => TransfersRepository(ref.watch(transfersApiProvider)),
);

final incomesApiProvider = Provider<IncomesApi>(
  (ref) => IncomesApi(ref.watch(apiClientProvider)),
);

final incomesRepositoryProvider = Provider<IncomesRepository>(
  (ref) => IncomesRepository(ref.watch(incomesApiProvider)),
);

final reportsApiProvider = Provider<ReportsApi>(
  (ref) => ReportsApi(ref.watch(apiClientProvider)),
);

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(reportsApiProvider)),
);

typedef IncomePendingKey = ({IncomeApiScope scope, int companyId});

final incomePendingActionCountProvider =
    FutureProvider.autoDispose.family<int, IncomePendingKey>(
  (ref, key) async {
    return ref.read(incomesRepositoryProvider).pendingActionCount(
          scope: key.scope,
          companyId: key.companyId,
        );
  },
);

typedef CombinedPendingKey = ({TransferApiScope scope, int companyId});

/// Сумма «ожидают действия» для переводов, поступлений и отчётов (ТЗ-06.1 + ТЗ-10C).
final combinedOperationsPendingCountProvider =
    FutureProvider.autoDispose.family<int, CombinedPendingKey>(
  (ref, key) async {
    final transfers = await ref.watch(
      transferPendingActionCountProvider((scope: key.scope, companyId: key.companyId)).future,
    );
    final incomeScope =
        key.scope == TransferApiScope.company ? IncomeApiScope.company : IncomeApiScope.personal;
    final incomes = await ref.watch(
      incomePendingActionCountProvider((scope: incomeScope, companyId: key.companyId)).future,
    );
    final reports = await ref.watch(
      reportPendingActionCountProvider((scope: key.scope, companyId: key.companyId)).future,
    );
    return transfers + incomes + reports;
  },
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

final reportPendingActionCountProvider =
    FutureProvider.autoDispose.family<int, TransferPendingKey>(
  (ref, key) async {
    return ref.read(reportsRepositoryProvider).pendingActionCount(
          scope: key.scope,
          companyId: key.companyId,
        );
  },
);
