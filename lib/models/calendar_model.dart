enum CalendarCourseEventType {
  watching,
  scheduled;

  String get label => switch (this) {
    CalendarCourseEventType.watching => 'Watching Course',
    CalendarCourseEventType.scheduled => 'Scheduled Course',
  };
}

class CalendarModel {
  const CalendarModel({
    this.scheduledCourses = const [],
    this.watchingCourses = const [],
  });

  final List<CalendarCourseEvent> scheduledCourses;
  final List<CalendarCourseEvent> watchingCourses;

  List<CalendarCourseEvent> get events => [
    ...watchingCourses,
    ...scheduledCourses,
  ];

  factory CalendarModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return CalendarModel(
      scheduledCourses: ((payload['scheduled_courses'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (json) => CalendarCourseEvent.fromJson(
              json,
              type: CalendarCourseEventType.scheduled,
            ),
          )
          .toList(),
      watchingCourses: ((payload['watching_courses'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (json) => CalendarCourseEvent.fromJson(
              json,
              type: CalendarCourseEventType.watching,
            ),
          )
          .toList(),
    );
  }
}

class CalendarCourseEvent {
  const CalendarCourseEvent({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.type,
    this.thumbnailUrl,
    this.startDate,
    this.endDate,
    this.totalVideos = 0,
    this.watchedVideos = 0,
  });

  final String id;
  final String courseId;
  final String courseName;
  final CalendarCourseEventType type;
  final String? thumbnailUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalVideos;
  final int watchedVideos;

  String get navigationCourseId => id.isNotEmpty ? id : courseId;

  bool occursOn(DateTime date) {
    final start = startDate;
    if (start == null) return false;
    return _sameDate(start, date);
  }

  factory CalendarCourseEvent.fromJson(
    Map<String, dynamic> json, {
    required CalendarCourseEventType type,
  }) {
    return CalendarCourseEvent(
      id: _nonEmptyString(json['id']),
      courseId: _nonEmptyString(json['course_id']),
      courseName: _nonEmptyString(json['course_name'] ?? json['title']),
      type: type,
      thumbnailUrl:
          _nullableString(json['thumbnail_url']) ??
          _nullableString(json['course_thumbnail_url']) ??
          _nullableString(json['thumbnail']) ??
          _nullableString(json['course_thumbnail']) ??
          _nullableString(json['image']),
      startDate: _parseDate(json['start_date'] ?? json['scheduled_at']),
      endDate: _parseDate(json['end_date']),
      totalVideos: _toInt(json['total_videos']),
      watchedVideos: _toInt(json['watched_videos']),
    );
  }
}

bool _sameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

DateTime? _parseDate(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst(' ', 'T'));
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
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
