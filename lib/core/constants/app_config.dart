class AppConfig {
  AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://srmcare.in/api/',
  );

  static const appName = 'THC Learning';
  static const requestTimeout = Duration(seconds: 30);
  static const pageSize = 20;
}
