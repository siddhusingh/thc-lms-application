class AppConfig {
  AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://srmcare.in/api/',
  );
  static const disableLessonFaceVerification = bool.fromEnvironment(
    'DISABLE_LESSON_FACE_VERIFICATION',
    defaultValue: false,
  );

  static const appName = 'THC Learning';
  static const requestTimeout = Duration(seconds: 30);
  static const pageSize = 20;
}
