import '../domain/project_participant.dart';
import 'project_participants_api.dart';

class ProjectParticipantsRepository {
  final ProjectParticipantsApi _api;
  ProjectParticipantsRepository(this._api);

  Future<List<ProjectParticipant>> list({
    required int companyId,
    required int projectId,
    int page = 1,
    int perPage = 50,
  }) async {
    final json = await _api.listParticipants(
      companyId: companyId,
      projectId: projectId,
      page: page,
      perPage: perPage,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final items = data['items'] as List;
    return items
        .map((e) => ProjectParticipant.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<ProjectParticipant> add({
    required int companyId,
    required int projectId,
    required int counterpartyId,
    required String role,
  }) async {
    final json = await _api.addParticipant(
      companyId: companyId,
      projectId: projectId,
      counterpartyId: counterpartyId,
      role: role,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final p = (data['participant'] as Map).cast<String, dynamic>();
    return ProjectParticipant.fromJson(p);
  }

  Future<ProjectParticipant> updateRole({
    required int companyId,
    required int projectId,
    required int participantId,
    required String role,
  }) async {
    final json = await _api.updateParticipantRole(
      companyId: companyId,
      projectId: projectId,
      participantId: participantId,
      role: role,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final p = (data['participant'] as Map).cast<String, dynamic>();
    return ProjectParticipant.fromJson(p);
  }

  Future<void> remove({
    required int companyId,
    required int projectId,
    required int participantId,
  }) async {
    await _api.removeParticipant(
      companyId: companyId,
      projectId: projectId,
      participantId: participantId,
    );
  }
}
