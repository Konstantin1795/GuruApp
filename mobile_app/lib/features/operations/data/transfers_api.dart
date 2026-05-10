import '../../../core/api/api_client.dart';

/// ТЗ-05.3: company-workspace — OWNER/PARTNER; personal-workspace — исполнители (создание только сотрудник 1-го порядка).
enum TransferApiScope {
  company,
  personal,
}

class TransfersApi {
  final ApiClient _api;
  TransfersApi(this._api);

  String _basePath({required TransferApiScope scope, required int companyId, required int projectId}) {
    return switch (scope) {
      TransferApiScope.company => '/company-workspace/$companyId/projects/$projectId/operations/transfers',
      TransferApiScope.personal => '/personal-workspace/projects/$projectId/operations/transfers',
    };
  }

  Future<Map<String, dynamic>> list({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int page,
    required int perPage,
  }) =>
      _api.getJson(
        _basePath(scope: scope, companyId: companyId, projectId: projectId),
        query: {'page': page, 'per_page': perPage},
      );

  Future<Map<String, dynamic>> listRecipients({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required String transferTargetType,
  }) =>
      _api.getJson(
        '${_basePath(scope: scope, companyId: companyId, projectId: projectId)}/recipients',
        query: {'transfer_target_type': transferTargetType},
      );

  Future<Map<String, dynamic>> create({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    int? receiverProjectParticipantId,
    int? receiverCounterpartyId,
    required String transferTargetType,
    required String amount,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'transfer_target_type': transferTargetType,
      'amount': amount,
    };
    if (comment != null && comment.trim().isNotEmpty) {
      body['comment'] = comment.trim();
    }
    if (receiverProjectParticipantId != null) {
      body['receiver_project_participant_id'] = receiverProjectParticipantId;
    }
    if (receiverCounterpartyId != null) {
      body['receiver_counterparty_id'] = receiverCounterpartyId;
    }
    return _api.postJson(
      _basePath(scope: scope, companyId: companyId, projectId: projectId),
      body: body,
    );
  }

  Future<Map<String, dynamic>> show({
    required TransferApiScope scope,
    required int companyId,
    required int projectId,
    required int transferId,
  }) =>
      _api.getJson(
        '${_basePath(scope: scope, companyId: companyId, projectId: projectId)}/$transferId',
      );
}
