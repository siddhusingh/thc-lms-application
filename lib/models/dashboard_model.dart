import 'course_model.dart';

class DashboardModel {
  const DashboardModel({
    this.studentName = 'Student',
    this.enrolledCourses = 0,
    this.completedCourses = 0,
    this.certificates = 0,
    this.watchTimeMinutes = 0,
    this.continueLearning,
    this.recentActivities = const [],
    this.upcomingAssessments = const [],
  });

  final String studentName;
  final int enrolledCourses;
  final int completedCourses;
  final int certificates;
  final int watchTimeMinutes;
  final CourseModel? continueLearning;
  final List<String> recentActivities;
  final List<String> upcomingAssessments;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final continueJson = json['continue_learning'];
    return DashboardModel(
      studentName: '${json['student_name'] ?? json['name'] ?? 'Student'}',
      enrolledCourses: _toInt(
        json['enrolled_courses'] ?? json['total_available_course'],
      ),
      completedCourses: _toInt(
        json['completed_courses'] ?? json['completed_course'],
      ),
      certificates: _toInt(json['certificates']),
      watchTimeMinutes: _toInt(
        json['watch_time_minutes'] ??
            json['watch_time'] ??
            json['learning_time'],
      ),
      continueLearning: continueJson is Map<String, dynamic>
          ? CourseModel.fromJson(continueJson)
          : null,
      recentActivities: ((json['recent_activities'] as List?) ?? [])
          .map((item) => item.toString())
          .toList(),
      upcomingAssessments: ((json['upcoming_assessments'] as List?) ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
