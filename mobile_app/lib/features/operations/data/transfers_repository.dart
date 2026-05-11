import '../../../core/api/api_models.dart';
import '../domain/transfer_detail_view.dart';
import '../domain/transfer_operation.dart';
import '../domain/transfer_recipient_pick.dart';
import '../domain/transfer_target_type.dart';
import 'transfers_api.dart';

class TransfersRepository {
  final TransfersApi _api;
  TransfersRepository(this._api);

  static const Set<String> commentRequiredKeys = {
    'reject_project_head',
    'return_to_created',
    'rollback_completed',
    'return_completed_to_project_head_approval',
  };

  static String _actionSegment(String backendKey) => backendKey.replaceAll('_', '-');

  Future<Paginated<TransferOperation>> list({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int page,
    required int perPage,
  }) async {
    final json = await _api.list(
      scope: scope,
      companyId: companyId,
      projectId: projectId,
      page: page,
      perPage: perPage,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<TransferOperation>.fromJson(data, parseItem: TransferOperation.fromJson);
  }

  Future<List<TransferRecipientPick>> listRecipients({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required TransferTargetType targetType,
  }) async {
    final json = await _api.listRecipients(
      scope: scope,
      companyId: companyId,
      projectId: projectId,
      transferTargetType: targetType.toJson(),
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final raw = (data['recipients'] as List).cast<dynamic>();
    return raw
        .map((e) => TransferRecipientPick.fromJson((e as Map).cast<String, dynamic>(), targetType))
        .toList(growable: false);
  }

  Future<TransferOperation> create({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    int? receiverProjectParticipantId,
    int? receiverCounterpartyId,
    required TransferTargetType targetType,
    required String amount,
    String? comment,
  }) async {
    final json = await _api.create(
      scope: scope,
      companyId: companyId,
      projectId: projectId,
      receiverProjectParticipantId: receiverProjectParticipantId,
      receiverCounterpartyId: receiverCounterpartyId,
      transferTargetType: targetType.toJson(),
      amount: amount,
      comment: comment,
    );
    if (json['ok'] != true) {
      throw StateError('create transfer: ok != true');
    }
    final rawData = json['data'];
    if (rawData is! Map) {
      throw StateError('create transfer: missing data');
    }
    final data = Map<String, dynamic>.from(rawData);
    final rawTransfer = data['transfer'];
    if (rawTransfer is! Map) {
      throw StateError('create transfer: missing transfer');
    }
    return TransferOperation.fromJson(Map<String, dynamic>.from(rawTransfer));
  }

  Future<TransferDetailView> showDetail({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int transferId,
  }) async {
    final json = await _api.show(
      scope: scope,
      companyId: companyId,
      projectId: projectId,
      transferId: transferId,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return TransferDetailView.fromShowJson(data);
  }

  Future<int> pendingActionCount({
    required TransferApiScope scope,
    required int companyId,
  }) async {
    final json = await _api.pendingActionCount(scope: scope, companyId: companyId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final v = data['pending_action_count'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  Future<Paginated<TransferOperation>> listHistoryAggregated({
    required TransferApiScope scope,
    required int companyId,
    required int page,
    required int perPage,
  }) async {
    final json = await _api.listHistoryAggregated(
      scope: scope,
      companyId: companyId,
      page: page,
      perPage: perPage,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<TransferOperation>.fromJson(data, parseItem: TransferOperation.fromJson);
  }

  /// Выполняет переход по ключу из [TransferDetailView.availableActions] (snake_case).
  Future<TransferOperation> performTransferAction({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int transferId,
    required String actionKey,
    String? comment,
  }) async {
    if (commentRequiredKeys.contains(actionKey)) {
      final c = comment?.trim() ?? '';
      if (c.isEmpty) {
        throw ArgumentError('Комментарий обязателен для действия $actionKey');
      }
    }

    final segment = _actionSegment(actionKey);
    final body = <String, dynamic>{};
    if (commentRequiredKeys.contains(actionKey)) {
      body['comment'] = comment!.trim();
    }

    final json = await _api.postTransferAction(
      scope: scope,
      companyId: companyId,
      projectId: projectId,
      transferId: transferId,
      actionSegment: segment,
      body: body.isEmpty ? null : body,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final transfer = (data['transfer'] as Map).cast<String, dynamic>();
    return TransferOperation.fromJson(transfer);
  }
}
