import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/company_workspace/presentation/company_workspace_shell.dart';
import '../../features/personal_workspace/presentation/personal_workspace_shell.dart';
import '../../features/workspaces/presentation/create_company_screen.dart';
import '../../features/workspaces/presentation/workspace_entry_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ValueNotifier<AuthState>(ref.read(authControllerProvider));

  // Refresh router redirect logic on auth state changes.
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    authListenable.value = next;
  });

  bool isAuthRoute(String loc) => loc == '/login' || loc == '/register';

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = authListenable.value;
      final loc = state.uri.toString();

      final onSplash = loc == '/';
      final onAuth = isAuthRoute(loc);

      // While bootstrapping, always stay on splash.
      if (auth.status == AuthStatus.initial || auth.status == AuthStatus.loading) {
        return onSplash ? null : '/';
      }

      // Treat error as unauthenticated for navigation.
      if (auth.status == AuthStatus.unauthenticated || auth.status == AuthStatus.error) {
        // Never stay on splash when unauthenticated.
        // Allow only /login and /register to be shown.
        return onAuth ? null : '/login';
      }

      // Authenticated: never stay on splash/auth screens.
      if (auth.status == AuthStatus.authenticated) {
        if (onSplash || onAuth) return '/workspaces';
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/workspaces', builder: (context, state) => const WorkspaceEntryScreen()),
      GoRoute(path: '/create-company', builder: (context, state) => const CreateCompanyScreen()),
      GoRoute(
        path: '/company/:companyId',
        builder: (context, state) =>
            CompanyWorkspaceShell(companyId: int.parse(state.pathParameters['companyId']!)),
      ),
      GoRoute(path: '/personal', builder: (context, state) => const PersonalWorkspaceShell()),
    ],
  );
});

