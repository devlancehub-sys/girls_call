/// Production API server.
class AppConfig {
  AppConfig._();

  static const String serverUrl = 'https://api.talkymate.in';

  static const String apiBaseUrl = '$serverUrl/api';
  static const String socketUrl = serverUrl;

  static const int zegoAppId = 2080383804;
}
