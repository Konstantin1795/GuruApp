import '../../../core/api/api_models.dart';
import '../domain/transfer_operation.dart';
import '../domain/transfer_target_type.dart';
import 'transfers_api.dart';

class TransfersRepository {
  final TransfersApi _api;
  TransfersRepository(this._api);

  Future<Paginated<TransferOperation>> list({
    required int companyId,
    required int projectId,
    required int page,
    required int perPage,
  }) async {
    final json = await _api.list(
      companyId: companyId,
      projectId: projectId,
      page: page,
      perPage: perPage,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Paginated<TransferOperation>.fromJson(data, parseItem: TransferOperation.fromJson);
  }

  Future<TransferOperation> create({
    required int companyId,
    required int projectId,
    required int receiverProjectParticipantId,
    required TransferTargetType targetType,
    required String amount,
    String? comment,
  }) async {
    final json = await _api.create(
      companyId: companyId,
      projectId: projectId,
      receiverProjectParticipantId: receiverProjectParticipantId,
      transferTargetType: targetType.toJson(),
      amount: amount,
      comment: comment,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final transfer = (data['transfer'] as Map).cast<String, dynamic>();
    return TransferOperation.fromJson(transfer);
  }

  Future<TransferOperation> show({
    required int companyId,
    required int projectId,
    required int transferId,
  }) async {
    final json = await _api.show(companyId: companyId, projectId: projectId, transferId: transferId);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final transfer = (data['transfer'] as Map).cast<String, dynamic>();
    return TransferOperation.fromJson(transfer);
  }
}
