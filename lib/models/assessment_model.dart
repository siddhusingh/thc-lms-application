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

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

bool _toBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}
