import '../../../core/api/api_models.dart';
import '../domain/transfer_operation.dart';
import '../domain/transfer_recipient_pick.dart';
import '../domain/transfer_target_type.dart';
import 'transfers_api.dart';

class TransfersRepository {
  final TransfersApi _api;
  TransfersRepository(this._api);

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
    final data = (json['data'] as Map).cast<String, dynamic>();
    final transfer = (data['transfer'] as Map).cast<String, dynamic>();
    return TransferOperation.fromJson(transfer);
  }

  Future<TransferOperation> show({
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
    final transfer = (data['transfer'] as Map).cast<String, dynamic>();
    return TransferOperation.fromJson(transfer);
  }
}
