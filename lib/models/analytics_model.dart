class AnalyticsModel {
  const AnalyticsModel({
    this.startDate = '',
    this.endDate = '',
    this.studyTime = '0 Hrs. 0Min',
    this.activeDays = 0,
    this.loginSessions = 0,
    this.completedCourses = 0,
    this.assessments = 0,
    this.studyTimeGraph = const [],
    this.timeSpentCourses = const [],
    this.assessmentsGraph = const [],
    this.loginSessionsGraph = const [],
  });

  final String startDate;
  final String endDate;
  final String studyTime;
  final int activeDays;
  final int loginSessions;
  final int completedCourses;
  final int assessments;
  final List<AnalyticsStudyTimePoint> studyTimeGraph;
  final List<AnalyticsCourseTime> timeSpentCourses;
  final List<AnalyticsAssessmentScore> assessmentsGraph;
  final List<AnalyticsLoginSession> loginSessionsGraph;

  bool get hasChartData {
    return studyTimeGraph.any((point) => point.hours > 0) ||
        timeSpentCourses.any(
          (course) => course.totalSeconds > 0 || course.percentage > 0,
        ) ||
        assessmentsGraph.isNotEmpty ||
        loginSessionsGraph.any((session) => session.totalLogins > 0);
  }

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final rawStudyGraph = payload['study_time_graph'] is List
        ? payload['study_time_graph']
        : payload['graph'];

    return AnalyticsModel(
      startDate: _stringValue(payload['start_date']),
      endDate: _stringValue(payload['end_date']),
      studyTime: _stringValue(payload['study_time'], fallback: '0 Hrs. 0Min'),
      activeDays: _toInt(payload['active_days']),
      loginSessions: _toInt(payload['login_sessions']),
      completedCourses: _toInt(payload['completed_courses']),
      assessments: _toInt(payload['assessments']),
      studyTimeGraph: ((rawStudyGraph as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsStudyTimePoint.fromJson)
          .toList(),
      timeSpentCourses:
          ((payload['time_spent_courses'] as List?) ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AnalyticsCourseTime.fromJson)
              .toList(),
      assessmentsGraph: ((payload['assessments_graph'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsAssessmentScore.fromJson)
          .toList(),
      loginSessionsGraph:
          ((payload['login_sessions_graph'] as List?) ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AnalyticsLoginSession.fromJson)
              .toList(),
    );
  }
}

class AnalyticsStudyTimePoint {
  const AnalyticsStudyTimePoint({required this.watchDate, this.hours = 0});

  final String watchDate;
  final double hours;

  factory AnalyticsStudyTimePoint.fromJson(Map<String, dynamic> json) {
    return AnalyticsStudyTimePoint(
      watchDate: _stringValue(json['watch_date']),
      hours: _toDouble(json['hours']),
    );
  }
}

class AnalyticsCourseTime {
  const AnalyticsCourseTime({
    required this.id,
    required this.title,
    this.totalSeconds = 0,
    this.percentage = 0,
    this.formattedTime = '0 hrs 0 mins',
  });

  final String id;
  final String title;
  final int totalSeconds;
  final double percentage;
  final String formattedTime;

  String get displayTitle => title.isEmpty ? 'Untitled course' : title;

  factory AnalyticsCourseTime.fromJson(Map<String, dynamic> json) {
    final seconds = _toInt(json['total_seconds']);
    return AnalyticsCourseTime(
      id: _stringValue(json['id']),
      title: _stringValue(json['title'] ?? json['course_title']),
      totalSeconds: seconds,
      percentage: _toDouble(json['percentage']),
      formattedTime: _stringValue(
        json['formatted_time'],
        fallback: _formatSeconds(seconds),
      ),
    );
  }
}

class AnalyticsAssessmentScore {
  const AnalyticsAssessmentScore({
    required this.title,
    required this.assessmentType,
    required this.timeTaken,
    this.lastCompletedAt,
    this.totalMarks = 0,
    this.obtainedMarks = 0,
    this.percentage = 0,
  });

  final String title;
  final String assessmentType;
  final DateTime? lastCompletedAt;
  final String timeTaken;
  final int totalMarks;
  final int obtainedMarks;
  final double percentage;

  String get displayTitle => title.isEmpty ? 'Assessment' : title;

  String get displayAssessmentType {
    if (assessmentType.isEmpty) return 'Assessment';
    return '${assessmentType[0].toUpperCase()}${assessmentType.substring(1)}';
  }

  String get scoreLabel => '$obtainedMarks/$totalMarks';

  factory AnalyticsAssessmentScore.fromJson(Map<String, dynamic> json) {
    return AnalyticsAssessmentScore(
      title: _stringValue(json['title'] ?? json['assessment_title']),
      assessmentType: _stringValue(json['assessment_type']),
      lastCompletedAt: _toDateTime(json['last_completed_at']),
      timeTaken: _stringValue(json['time_taken'], fallback: '0 mins'),
      totalMarks: _toInt(json['total_marks']),
      obtainedMarks: _toInt(json['obtained_marks']),
      percentage: _toDouble(json['percentage']),
    );
  }
}

class AnalyticsLoginSession {
  const AnalyticsLoginSession({
    required this.loginDate,
    this.loginDateTime,
    this.totalLogins = 0,
  });

  final String loginDate;
  final DateTime? loginDateTime;
  final int totalLogins;

  factory AnalyticsLoginSession.fromJson(Map<String, dynamic> json) {
    final label = _stringValue(json['login_date']);
    return AnalyticsLoginSession(
      loginDate: label,
      loginDateTime: _toLooseDate(label),
      totalLogins: _toInt(json['total_logins']),
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

String _stringValue(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

DateTime? _toDateTime(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

DateTime? _toLooseDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed != null) return parsed;

  final parts = value.trim().split(RegExp(r'\s+'));
  if (parts.length < 3) return null;
  final day = int.tryParse(parts[0]);
  final month = _monthNumber(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}

int? _monthNumber(String value) {
  switch (value.toLowerCase()) {
    case 'jan':
    case 'january':
      return 1;
    case 'feb':
    case 'february':
      return 2;
    case 'mar':
    case 'march':
      return 3;
    case 'apr':
    case 'april':
      return 4;
    case 'may':
      return 5;
    case 'jun':
    case 'june':
      return 6;
    case 'jul':
    case 'july':
      return 7;
    case 'aug':
    case 'august':
      return 8;
    case 'sep':
    case 'sept':
    case 'september':
      return 9;
    case 'oct':
    case 'october':
      return 10;
    case 'nov':
    case 'november':
      return 11;
    case 'dec':
    case 'december':
      return 12;
  }
  return null;
}

String _formatSeconds(int seconds) {
  final totalMinutes = (seconds / 60).round();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '$hours hrs $minutes mins';
}
