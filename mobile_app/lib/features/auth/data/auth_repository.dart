import '../../../core/storage/token_storage.dart';
import '../domain/auth_session.dart';
import '../domain/user.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi _api;
  final TokenStorage _tokenStorage;

  AuthRepository(this._api, this._tokenStorage);

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  }) async {
    final json = await _api.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      deviceName: deviceName,
    );
    final data = (json['data'] as Map).cast<String, dynamic>();
    final user = User.fromJson((data['user'] as Map).cast<String, dynamic>());
    final token = data['token'] as String;
    await _tokenStorage.writeToken(token);
    return AuthSession(user: user, token: token);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final json = await _api.token(email: email, password: password, deviceName: deviceName);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final user = User.fromJson((data['user'] as Map).cast<String, dynamic>());
    final token = data['token'] as String;
    await _tokenStorage.writeToken(token);
    return AuthSession(user: user, token: token);
  }

  Future<User> me() async {
    final json = await _api.me();
    final data = (json['data'] as Map).cast<String, dynamic>();
    return User.fromJson((data['user'] as Map).cast<String, dynamic>());
  }

  Future<void> logout() async {
    await _api.logout();
    await _tokenStorage.clearToken();
  }

  Future<String?> readToken() => _tokenStorage.readToken();

  Future<void> clearToken() => _tokenStorage.clearToken();
}

