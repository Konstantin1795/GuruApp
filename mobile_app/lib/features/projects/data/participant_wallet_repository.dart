import '../domain/participant_wallet.dart';
import 'participant_wallet_api.dart';

class ParticipantWalletRepository {
  final ParticipantWalletApi _api;
  ParticipantWalletRepository(this._api);

  Future<ParticipantWallet> get({
    required int companyId,
    required int projectId,
    required int participantId,
  }) async {
    final json = await _api.getWallet(
      companyId: companyId,
      projectId: projectId,
      participantId: participantId,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final w = (data['wallet'] as Map).cast<String, dynamic>();
    return ParticipantWallet.fromJson(w);
  }
}
