/// Build-time configuration, supplied via `--dart-define-from-file=.env`.
///
/// There is deliberately no default for [apiBaseUrl]: a wrong-but-plausible default
/// (the old `http://localhost:5000`) fails silently on every real device, which is
/// how ride uploads could go unnoticed. An empty value is checked at startup instead.
class EnvConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String googleClientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');

  /// False when the app was built without `--dart-define-from-file`. Every network
  /// call will fail; `main()` logs a loud warning rather than letting it look like
  /// a connectivity problem.
  static bool get isConfigured => apiBaseUrl.isNotEmpty;
}
