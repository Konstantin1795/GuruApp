import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/guru_theme.dart';
import 'core/routing/router_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          title: 'GURU',
          theme: GuruTheme.light(),
          darkTheme: GuruTheme.dark(),
          themeMode: ThemeMode.dark,
          routerConfig: router,
        );
      },
    );
  }
}
