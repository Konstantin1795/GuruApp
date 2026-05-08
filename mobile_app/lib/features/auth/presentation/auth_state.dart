import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../providers.dart';
import '../../../core/providers.dart';
import '../../workspaces/providers.dart';

enum AuthStatus { initial, loading, unauthenticated, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState(this.status, {this.errorMessage});
}

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;
  final Logger _logger;

  AuthController(this._ref)
      : _logger = _ref.read(loggerProvider),
        super(const AuthState(AuthStatus.initial)) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _logger.i('Splash bootstrap started');
    state = const AuthState(AuthStatus.loading);

    final auth = _ref.read(authRepositoryProvider);

    String? token;
    try {
      token = await auth.readToken().timeout(const Duration(seconds: 8));
    } catch (e, st) {
      _logger.e('Token read failed (treating as no token).', error: e, stackTrace: st);
      token = null;
    }

    _logger.i('Token exists: ${token != null && token.isNotEmpty}');

    if (token == null || token.isEmpty) {
      _logger.i('Redirect to login (no token)');
      state = const AuthState(AuthStatus.unauthenticated);
      _logger.i('Bootstrap finished (unauthenticated)');
      return;
    }

    try {
      // Validate token by calling /auth/me.
      await auth.me().timeout(const Duration(seconds: 10));
      _logger.i('Auth me success');

      // Warm up workspaces to ensure backend connectivity and avoid later hangs.
      await _ref.read(workspacesRepositoryProvider).fetch().timeout(const Duration(seconds: 10));
      _logger.i('Workspaces loaded');

      state = const AuthState(AuthStatus.authenticated);
      _logger.i('Bootstrap finished (authenticated)');
    } catch (e, st) {
      _logger.e(
        'Auth me failed (backend unreachable or token invalid).',
        error: e,
        stackTrace: st,
      );
      await auth.clearToken();
      _logger.i('Redirect to login (bootstrap error)');
      state = AuthState(AuthStatus.error, errorMessage: e.toString());
      state = const AuthState(AuthStatus.unauthenticated);
      _logger.i('Bootstrap finished (unauthenticated)');
    }
  }

  Future<void> setAuthenticated() async {
    state = const AuthState(AuthStatus.authenticated);
  }

  Future<void> logout() async {
    try {
      await _ref.read(authRepositoryProvider).logout();
    } catch (e, st) {
      _logger.w('Logout failed, clearing local token anyway.', error: e, stackTrace: st);
      await _ref.read(authRepositoryProvider).clearToken();
    }
    state = const AuthState(AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));

