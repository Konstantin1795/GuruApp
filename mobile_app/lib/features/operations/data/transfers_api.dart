import '../../../core/api/api_client.dart';

class TransfersApi {
  final ApiClient _api;
  TransfersApi(this._api);

  Future<Map<String, dynamic>> list({
    required int companyId,
    required int projectId,
    required int page,
    required int perPage,
  }) =>
      _api.getJson(
        '/company-workspace/$companyId/projects/$projectId/operations/transfers',
        query: {'page': page, 'per_page': perPage},
      );

  Future<Map<String, dynamic>> create({
    required int companyId,
    required int projectId,
    required int receiverProjectParticipantId,
    required String transferTargetType,
    required String amount,
    String? comment,
  }) =>
      _api.postJson(
        '/company-workspace/$companyId/projects/$projectId/operations/transfers',
        body: {
          'receiver_project_participant_id': receiverProjectParticipantId,
          'transfer_target_type': transferTargetType,
          'amount': amount,
          if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
        },
      );

  Future<Map<String, dynamic>> show({
    required int companyId,
    required int projectId,
    required int transferId,
  }) =>
      _api.getJson(
        '/company-workspace/$companyId/projects/$projectId/operations/transfers/$transferId',
      );
}
