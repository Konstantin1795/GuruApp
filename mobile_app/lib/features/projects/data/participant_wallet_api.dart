import '../../../core/api/api_client.dart';

class ParticipantWalletApi {
  final ApiClient _api;
  ParticipantWalletApi(this._api);

  Future<Map<String, dynamic>> getWallet({
    required int companyId,
    required int projectId,
    required int participantId,
  }) =>
      _api.getJson(
        '/company-workspace/$companyId/projects/$projectId/participants/$participantId/wallet',
      );
}
