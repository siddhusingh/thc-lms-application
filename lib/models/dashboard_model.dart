import 'course_model.dart';

class DashboardModel {
  const DashboardModel({
    this.studentName = 'Student',
    this.enrolledCourses = 0,
    this.inProgressCourses = 0,
    this.completedCourses = 0,
    this.certificates = 0,
    this.watchTimeMinutes = 0,
    this.learningTimeUnit = 'Minutes',
    this.continueLearning,
    this.progress = const [],
    this.weeklyStudyHours = const [0, 0, 0, 0, 0, 0, 0],
    this.weeklyLoginCounts = const [0, 0, 0, 0, 0, 0, 0],
    this.courseCompletionSeries = const [],
    this.recentActivities = const [],
    this.upcomingAssessments = const [],
  });

  final String studentName;
  final int enrolledCourses;
  final int? inProgressCourses;
  final int completedCourses;
  final int certificates;
  final int watchTimeMinutes;
  final String? learningTimeUnit;
  final CourseModel? continueLearning;
  final List<DashboardCourseProgress> progress;
  final List<double> weeklyStudyHours;
  final List<int> weeklyLoginCounts;
  final List<DashboardCourseCompletionSeries> courseCompletionSeries;
  final List<String> recentActivities;
  final List<String> upcomingAssessments;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final continueJson = json['continue_learning'];
    return DashboardModel(
      studentName: '${json['student_name'] ?? json['name'] ?? 'Student'}',
      enrolledCourses: _toInt(
        json['enrolled_courses'] ?? json['total_available_course'],
      ),
      inProgressCourses: _toInt(
        json['in_progress_course'] ?? json['in_progress_courses'],
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
      learningTimeUnit:
          '${json['learning_time_unit'] ?? 'Minutes'}'.trim().isEmpty
          ? 'Minutes'
          : '${json['learning_time_unit'] ?? 'Minutes'}',
      continueLearning: continueJson is Map<String, dynamic>
          ? CourseModel.fromJson(continueJson)
          : null,
      progress: ((json['progress'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardCourseProgress.fromJson)
          .toList(),
      weeklyStudyHours: _weeklyStudyHours(json['weekly_graph']),
      weeklyLoginCounts: _weeklyLoginCounts(json['weekly_login']),
      courseCompletionSeries: ((json['com_percent'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardCourseCompletionSeries.fromJson)
          .toList(),
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

  static List<double> _weeklyStudyHours(Object? value) {
    final items = value is List ? value : const [];
    return List<double>.generate(
      7,
      (index) => index < items.length ? _toDouble(items[index]) : 0,
      growable: false,
    );
  }

  static List<int> _weeklyLoginCounts(Object? value) {
    final items = value is List ? value : const [];
    return List<int>.generate(
      7,
      (index) => index < items.length ? _toInt(items[index]) : 0,
      growable: false,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DashboardCourseProgress {
  const DashboardCourseProgress({
    required this.id,
    required this.courseId,
    required this.courseName,
    this.courseThumbnail,
    this.progressPercentage = 0,
  });

  final String id;
  final String courseId;
  final String courseName;
  final String? courseThumbnail;
  final double progressPercentage;

  String get navigationCourseId => id.isNotEmpty ? id : courseId;

  factory DashboardCourseProgress.fromJson(Map<String, dynamic> json) {
    return DashboardCourseProgress(
      id: '${json['id'] ?? ''}',
      courseId: '${json['course_id'] ?? json['id'] ?? ''}',
      courseName: '${json['course_name'] ?? json['title'] ?? ''}',
      courseThumbnail:
          json['course_thumbnail']?.toString() ??
          json['thumbnail_url']?.toString() ??
          json['thumbnail']?.toString(),
      progressPercentage: _toDouble(json['progress_percentage']),
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DashboardCourseCompletionSeries {
  const DashboardCourseCompletionSeries({
    required this.name,
    this.values = const [0, 0, 0, 0, 0, 0, 0],
  });

  static const _dayIndexes = {
    'mon': 0,
    'tue': 1,
    'wed': 2,
    'thu': 3,
    'fri': 4,
    'sat': 5,
    'sun': 6,
  };

  final String name;
  final List<double> values;

  factory DashboardCourseCompletionSeries.fromJson(Map<String, dynamic> json) {
    final values = List<double>.filled(7, 0, growable: false);
    for (final item in (json['data'] as List? ?? const [])) {
      if (item is! Map<String, dynamic>) continue;
      final dayIndex = _dayIndexes[item['x']?.toString().toLowerCase()];
      if (dayIndex == null) continue;
      values[dayIndex] = _toDouble(item['y']);
    }

    return DashboardCourseCompletionSeries(
      name: '${json['name'] ?? ''}',
      values: values,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
