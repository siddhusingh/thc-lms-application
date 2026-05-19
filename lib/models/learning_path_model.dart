class LearningPathModel {
  const LearningPathModel({
    this.summary = const LearningPathSummary(),
    this.courses = const [],
  });

  final LearningPathSummary summary;
  final List<LearningPathCourse> courses;

  factory LearningPathModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final summaryJson = payload['summary'] is Map<String, dynamic>
        ? payload['summary'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return LearningPathModel(
      summary: LearningPathSummary.fromJson(summaryJson),
      courses: ((payload['courses'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LearningPathCourse.fromJson)
          .toList(),
    );
  }
}

class LearningPathSummary {
  const LearningPathSummary({
    this.totalCourses = 0,
    this.progressPercentage = 0,
    this.watchedTime = '0 Minutes',
  });

  final int totalCourses;
  final double progressPercentage;
  final String watchedTime;

  factory LearningPathSummary.fromJson(Map<String, dynamic> json) {
    return LearningPathSummary(
      totalCourses: _toInt(json['total_courses']),
      progressPercentage: _toDouble(json['progress_percentage']),
      watchedTime: _nonEmptyString(json['watched_time'], fallback: '0 Minutes'),
    );
  }
}

class LearningPathCourse {
  const LearningPathCourse({
    required this.id,
    required this.courseId,
    required this.courseName,
    this.thumbnailUrl,
    this.status = '',
    this.progressPercentage = 0,
    this.totalSeconds = 0,
    this.totalWatchTime = '0',
    this.isCompleted = false,
    this.action = '',
  });

  final String id;
  final String courseId;
  final String courseName;
  final String? thumbnailUrl;
  final String status;
  final double progressPercentage;
  final int totalSeconds;
  final String totalWatchTime;
  final bool isCompleted;
  final String action;

  String get navigationCourseId => id.isNotEmpty ? id : courseId;

  factory LearningPathCourse.fromJson(Map<String, dynamic> json) {
    return LearningPathCourse(
      id: _nonEmptyString(json['id']),
      courseId: _nonEmptyString(json['course_id']),
      courseName: _nonEmptyString(json['course_name']),
      thumbnailUrl:
          _nullableString(json['course_thumbnail_url']) ??
          _nullableString(json['thumbnail_url']) ??
          _nullableString(json['course_thumbnail']) ??
          _nullableString(json['thumbnail']) ??
          _nullableString(json['image']),
      status: _nonEmptyString(json['status']),
      progressPercentage: _toDouble(json['progress_percentage']),
      totalSeconds: _toInt(json['total_seconds']),
      totalWatchTime: _nonEmptyString(json['total_watch_time'], fallback: '0'),
      isCompleted: _toBool(json['is_completed']),
      action: _nonEmptyString(json['action']),
    );
  }
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

String _nonEmptyString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
