import '../../../core/api/api_client.dart';

class AuthApi {
  final ApiClient _api;
  AuthApi(this._api);

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  }) {
    return _api.postJson(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': deviceName,
      },
    );
  }

  Future<Map<String, dynamic>> token({
    required String email,
    required String password,
    required String deviceName,
  }) {
    return _api.postJson(
      '/auth/token',
      body: {
        'email': email,
        'password': password,
        'device_name': deviceName,
      },
    );
  }

  Future<Map<String, dynamic>> me() => _api.getJson('/auth/me');

  Future<Map<String, dynamic>> logout() => _api.postJson('/auth/logout');
}

