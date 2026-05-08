class AppConfig {
  // Use 10.0.2.2 for Android emulator to reach host machine localhost.
  static const String defaultBaseUrl = String.fromEnvironment(
    'GURU_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static const Duration requestTimeout = Duration(seconds: 15);
}

