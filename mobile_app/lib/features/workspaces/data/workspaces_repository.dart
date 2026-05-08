import 'workspaces_api.dart';
import '../domain/workspaces.dart';

class WorkspacesRepository {
  final WorkspacesApi _api;
  WorkspacesRepository(this._api);

  Future<Workspaces> fetch() async {
    final json = await _api.getWorkspaces();
    final data = (json['data'] as Map).cast<String, dynamic>();
    return Workspaces.fromJson(data);
  }

  Future<int> createCompany({required String name}) async {
    final json = await _api.createCompany(name: name);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final company = (data['company'] as Map).cast<String, dynamic>();
    return company['id'] as int;
  }
}

