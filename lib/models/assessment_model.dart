class AssessmentModel {
  const AssessmentModel({
    required this.id,
    required this.title,
    this.courseTitle,
    this.videoTitle = '',
    this.assessmentType = '',
    this.lastCompletedAt,
    this.timeTaken = '',
    this.durationMinutes = 0,
    this.totalQuestions = 0,
    this.status = 'available',
    this.passPercentage = 0,
    this.totalMarks = 0,
    this.obtainedMarks = 0,
    this.percentage = 0,
  });

  final String id;
  final String title;
  final String? courseTitle;
  final String videoTitle;
  final String assessmentType;
  final DateTime? lastCompletedAt;
  final String timeTaken;
  final int durationMinutes;
  final int totalQuestions;
  final String status;
  final double passPercentage;
  final int totalMarks;
  final int obtainedMarks;
  final double percentage;

  String get displayTitle => title.isEmpty ? 'Assessment' : title;

  String get displayCourseTitle {
    final text = courseTitle?.trim() ?? '';
    return text.isEmpty ? 'Untitled course' : text;
  }

  String get displayAssessmentType {
    if (assessmentType.isEmpty) {
      final normalizedTitle = title.toLowerCase();
      if (normalizedTitle.contains('pre')) return 'Pre';
      if (normalizedTitle.contains('post')) return 'Post';
      return 'Assessment';
    }
    return '${assessmentType[0].toUpperCase()}${assessmentType.substring(1)}';
  }

  double get displayPercentage {
    if (percentage > 0) return percentage;
    if (totalMarks > 0) return obtainedMarks / totalMarks * 100;
    return passPercentage;
  }

  String get scoreLabel {
    if (totalMarks > 0) return '$obtainedMarks/$totalMarks';
    if (totalQuestions > 0) return '0/$totalQuestions';
    return '0/0';
  }

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: '${json['id'] ?? json['_id'] ?? json['assessment_id'] ?? ''}',
      title:
          '${json['title'] ?? json['name'] ?? json['assessment_title'] ?? ''}',
      courseTitle: json['course_title']?.toString(),
      videoTitle: _stringValue(json['video_title']),
      assessmentType: _stringValue(json['assessment_type']),
      lastCompletedAt: _toDateTime(json['last_completed_at']),
      timeTaken: _stringValue(json['time_taken']),
      durationMinutes: _toInt(
        json['duration_minutes'] ?? json['time_limit'] ?? json['time_taken'],
      ),
      totalQuestions: _toInt(
        json['total_questions'] ??
            json['question_count'] ??
            json['total_marks'],
      ),
      status: '${json['status'] ?? 'available'}',
      passPercentage: _toDouble(
        json['pass_percentage'] ?? json['passing_score'],
      ),
      totalMarks: _toInt(json['total_marks']),
      obtainedMarks: _toInt(json['obtained_marks']),
      percentage: _toDouble(json['percentage']),
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.question,
    this.options = const [],
  });

  final String id;
  final String question;
  final List<AnswerOptionModel> options;

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      question:
          '${json['question'] ?? json['question_text'] ?? json['title'] ?? ''}',
      options: ((json['options'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AnswerOptionModel.fromJson)
          .toList(),
    );
  }
}

class AnswerOptionModel {
  const AnswerOptionModel({required this.id, required this.text});

  final String id;
  final String text;

  factory AnswerOptionModel.fromJson(Map<String, dynamic> json) {
    return AnswerOptionModel(
      id: '${json['id'] ?? json['_id'] ?? json['value'] ?? ''}',
      text:
          '${json['text'] ?? json['option_text'] ?? json['label'] ?? json['option'] ?? ''}',
    );
  }
}

class AssessmentAttemptModel {
  const AssessmentAttemptModel({
    required this.attemptId,
    required this.questions,
    this.durationSeconds = 0,
    this.totalQuestions = 0,
    this.currentNumber = 0,
    this.nextQuestionId,
    this.isLast = false,
  });

  final String attemptId;
  final List<QuestionModel> questions;
  final int durationSeconds;
  final int totalQuestions;
  final int currentNumber;
  final String? nextQuestionId;
  final bool isLast;

  factory AssessmentAttemptModel.fromJson(Map<String, dynamic> json) {
    final question = json['question'];
    return AssessmentAttemptModel(
      attemptId:
          '${json['attempt_id'] ?? json['attempt']?['id'] ?? json['id'] ?? ''}',
      questions: question is Map<String, dynamic>
          ? [QuestionModel.fromJson(question)]
          : ((json['questions'] as List?) ?? [])
                .whereType<Map<String, dynamic>>()
                .map(QuestionModel.fromJson)
                .toList(),
      durationSeconds: AssessmentModel._toInt(
        json['duration_seconds'] ?? json['time_limit_seconds'],
      ),
      totalQuestions: AssessmentModel._toInt(
        json['total_questions'] ?? json['question_count'],
      ),
      currentNumber: AssessmentModel._toInt(json['current_number']),
      nextQuestionId: _nullableString(json['next_question_id']),
      isLast: _toBool(json['is_last']),
    );
  }

  AssessmentAttemptModel copyWith({
    String? attemptId,
    List<QuestionModel>? questions,
    int? durationSeconds,
    int? totalQuestions,
    int? currentNumber,
    String? nextQuestionId,
    bool? isLast,
  }) {
    return AssessmentAttemptModel(
      attemptId: attemptId ?? this.attemptId,
      questions: questions ?? this.questions,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      currentNumber: currentNumber ?? this.currentNumber,
      nextQuestionId: nextQuestionId ?? this.nextQuestionId,
      isLast: isLast ?? this.isLast,
    );
  }
}

class AssessmentResultHistoryModel {
  const AssessmentResultHistoryModel({
    required this.assessmentId,
    required this.courseTitle,
    required this.videoTitle,
    required this.title,
    required this.assessmentType,
    required this.lastCompletedAt,
    required this.timeTaken,
    this.totalMarks = 0,
    this.obtainedMarks = 0,
    this.percentage = 0,
  });

  final String assessmentId;
  final String courseTitle;
  final String videoTitle;
  final String title;
  final String assessmentType;
  final DateTime? lastCompletedAt;
  final String timeTaken;
  final int totalMarks;
  final int obtainedMarks;
  final double percentage;

  String get displayTitle => title.isEmpty ? 'Assessment' : title;

  String get displayCourseTitle {
    return courseTitle.isEmpty ? 'Untitled course' : courseTitle;
  }

  String get displayAssessmentType {
    if (assessmentType.isEmpty) return 'Assessment';
    return '${assessmentType[0].toUpperCase()}${assessmentType.substring(1)}';
  }

  String get scoreLabel => '$obtainedMarks/$totalMarks';

  factory AssessmentResultHistoryModel.fromJson(Map<String, dynamic> json) {
    return AssessmentResultHistoryModel(
      assessmentId: _stringValue(json['assessment_id'] ?? json['id']),
      courseTitle: _stringValue(json['course_title']),
      videoTitle: _stringValue(json['video_title']),
      title: _stringValue(json['title'] ?? json['assessment_title']),
      assessmentType: _stringValue(json['assessment_type']),
      lastCompletedAt: _toDateTime(json['last_completed_at']),
      timeTaken: _stringValue(json['time_taken'], fallback: '0 mins'),
      totalMarks: AssessmentModel._toInt(json['total_marks']),
      obtainedMarks: AssessmentModel._toInt(json['obtained_marks']),
      percentage: AssessmentModel._toDouble(json['percentage']),
    );
  }
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
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

bool _toBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}
