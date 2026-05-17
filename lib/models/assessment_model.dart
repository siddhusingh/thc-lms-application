class AssessmentModel {
  const AssessmentModel({
    required this.id,
    required this.title,
    this.courseTitle,
    this.durationMinutes = 0,
    this.totalQuestions = 0,
    this.status = 'available',
    this.passPercentage = 0,
  });

  final String id;
  final String title;
  final String? courseTitle;
  final int durationMinutes;
  final int totalQuestions;
  final String status;
  final double passPercentage;

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      title: '${json['title'] ?? json['name'] ?? ''}',
      courseTitle: json['course_title']?.toString(),
      durationMinutes: _toInt(json['duration_minutes'] ?? json['time_limit']),
      totalQuestions: _toInt(json['total_questions'] ?? json['question_count']),
      status: '${json['status'] ?? 'available'}',
      passPercentage: _toDouble(
        json['pass_percentage'] ?? json['passing_score'],
      ),
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
      question: '${json['question'] ?? json['title'] ?? ''}',
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
      text: '${json['text'] ?? json['label'] ?? json['option'] ?? ''}',
    );
  }
}

class AssessmentAttemptModel {
  const AssessmentAttemptModel({
    required this.attemptId,
    required this.questions,
    this.durationSeconds = 0,
  });

  final String attemptId;
  final List<QuestionModel> questions;
  final int durationSeconds;

  factory AssessmentAttemptModel.fromJson(Map<String, dynamic> json) {
    return AssessmentAttemptModel(
      attemptId: '${json['attempt_id'] ?? json['id'] ?? ''}',
      questions: ((json['questions'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(QuestionModel.fromJson)
          .toList(),
      durationSeconds: AssessmentModel._toInt(
        json['duration_seconds'] ?? json['time_limit_seconds'],
      ),
    );
  }
}
