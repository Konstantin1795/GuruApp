import '../../../core/api/api_client.dart';

class ProjectParticipantsApi {
  final ApiClient _api;
  ProjectParticipantsApi(this._api);

  Future<Map<String, dynamic>> listParticipants({
    required int companyId,
    required int projectId,
    required int page,
    required int perPage,
  }) =>
      _api.getJson(
        '/company-workspace/$companyId/projects/$projectId/participants',
        query: {'page': page, 'per_page': perPage},
      );

  Future<Map<String, dynamic>> addParticipant({
    required int companyId,
    required int projectId,
    required int counterpartyId,
    required String role,
  }) =>
      _api.postJson(
        '/company-workspace/$companyId/projects/$projectId/participants',
        body: {
          'counterparty_id': counterpartyId,
          'role': role,
        },
      );

  Future<Map<String, dynamic>> updateParticipantRole({
    required int companyId,
    required int projectId,
    required int participantId,
    required String role,
  }) =>
      _api.patchJson(
        '/company-workspace/$companyId/projects/$projectId/participants/$participantId',
        body: {'role': role},
      );

  Future<Map<String, dynamic>> removeParticipant({
    required int companyId,
    required int projectId,
    required int participantId,
  }) =>
      _api.deleteJson(
        '/company-workspace/$companyId/projects/$projectId/participants/$participantId',
      );
}
