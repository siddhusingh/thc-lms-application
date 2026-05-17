class ApiEndpoints {
  ApiEndpoints._();

  static const login = 'student/login';
  static const register = 'student/register';
  static const forgotPassword = 'student/forgot-password';
  static const verifyOtp = 'student/verify-otp';
  static const resetPassword = 'student/reset-password';
  static const refreshToken = 'student/refresh';
  static const logout = 'student/logout';
  static const me = 'student/profile';

  static const faceRegister = 'student/face/register';
  static const faceVerify = 'student/face/verify';
  static const faceImages = 'student/face-images';

  static const dashboard = 'student/dashboard';
  static const courses = 'student/courses';
  static String course(String id) => 'student/course-detail';
  static const coursePlaylist = 'student/course-playlist';
  static const videoProgress = 'student/video-progress';
  static const checkVideoAssessment = 'student/check-video-assessment';
  static const checkCourseAssessment = 'student/check-course-assessment';

  static const assessments = 'student/results';
  static String assessment(String id) => 'student/assessment/question';
  static String startAssessment(String id) => 'student/assessment/start';
  static String submitAssessment(String attemptId) =>
      'student/assessment/finish';
  static String assessmentAttempts(String id) => 'student/results';

  static const certificates = 'student/certificates';
  static String certificate(String id) => 'student/certificates/$id';

  static const profile = 'student/profile';
  static const profileImage = 'student/profile-image';
  static const changePassword = 'student/profile/change-password';
  static const deviceToken = 'student/device-token';
}
