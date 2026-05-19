class StudyTimeModel {
  const StudyTimeModel({
    this.totalTime = '0 hrs 0 mins',
    this.averageTime = '0 hrs 0 mins',
    this.longestSession = '0 hrs 0 mins',
    this.pieChart = const [],
    this.graph = const [],
  });

  final String totalTime;
  final String averageTime;
  final String longestSession;
  final List<StudyTimeCourseSlice> pieChart;
  final List<StudyTimeGraphPoint> graph;

  bool get hasStudyTime {
    return pieChart.any(
          (item) => item.totalSeconds > 0 || item.percentage > 0,
        ) ||
        graph.any((item) => item.hours > 0);
  }

  factory StudyTimeModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return StudyTimeModel(
      totalTime: _nonEmptyString(
        payload['total_time'],
        fallback: '0 hrs 0 mins',
      ),
      averageTime: _nonEmptyString(
        payload['average_time'],
        fallback: '0 hrs 0 mins',
      ),
      longestSession: _nonEmptyString(
        payload['longest_session'],
        fallback: '0 hrs 0 mins',
      ),
      pieChart: ((payload['pie_chart'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StudyTimeCourseSlice.fromJson)
          .toList(),
      graph: ((payload['graph'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StudyTimeGraphPoint.fromJson)
          .toList(),
    );
  }
}

class StudyTimeCourseSlice {
  const StudyTimeCourseSlice({
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

  factory StudyTimeCourseSlice.fromJson(Map<String, dynamic> json) {
    final totalSeconds = _toInt(json['total_seconds']);
    return StudyTimeCourseSlice(
      id: _nonEmptyString(json['id']),
      title: _nonEmptyString(json['title'] ?? json['course_name']),
      totalSeconds: totalSeconds,
      percentage: _toDouble(json['percentage']),
      formattedTime: _nonEmptyString(
        json['formatted_time'],
        fallback: _formatSeconds(totalSeconds),
      ),
    );
  }
}

class StudyTimeGraphPoint {
  const StudyTimeGraphPoint({required this.watchDate, this.hours = 0});

  final String watchDate;
  final double hours;

  factory StudyTimeGraphPoint.fromJson(Map<String, dynamic> json) {
    return StudyTimeGraphPoint(
      watchDate: _nonEmptyString(json['watch_date']),
      hours: _toDouble(json['hours']),
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

String _nonEmptyString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _formatSeconds(int seconds) {
  final totalMinutes = (seconds / 60).round();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '$hours hrs $minutes mins';
}
