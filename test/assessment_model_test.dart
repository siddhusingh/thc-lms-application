import 'package:flutter_test/flutter_test.dart';
import 'package:thc_lms_mobile/models/assessment_model.dart';

void main() {
  test('question payload parses single-question assessment responses', () {
    final attempt = AssessmentAttemptModel.fromJson({
      'current_number': 1,
      'total_questions': 20,
      'next_question_id': 22,
      'is_last': false,
      'question': {
        'id': 21,
        'question_text': 'What is the capital of India?',
        'options': [
          {'id': '81', 'option_text': 'Mumbai'},
          {'id': '82', 'option_text': 'New Delhi'},
        ],
      },
    });

    expect(attempt.questions, hasLength(1));
    expect(attempt.questions.single.question, 'What is the capital of India?');
    expect(attempt.questions.single.options.first.text, 'Mumbai');
    expect(attempt.totalQuestions, 20);
    expect(attempt.currentNumber, 1);
    expect(attempt.nextQuestionId, '22');
    expect(attempt.isLast, isFalse);
  });

  test('question payload can carry the attempt id used for final submit', () {
    final attempt = AssessmentAttemptModel.fromJson({
      'attempt_id': 'attempt-42',
      'question': {'id': 'question-1', 'question_text': 'One plus one?'},
    });

    expect(attempt.attemptId, 'attempt-42');
  });

  test('result history parses assessment result payload values', () {
    final result = AssessmentResultHistoryModel.fromJson({
      'assessment_id': '4',
      'course_title': 'Where can I get some?',
      'video_title': 'Contrary to popular belief',
      'title': 'Pre Video Assess',
      'assessment_type': 'pre',
      'last_completed_at': '2026-05-17 23:23:32',
      'time_taken': '0 mins',
      'total_marks': '20',
      'obtained_marks': '4',
      'percentage': '20.00',
    });

    expect(result.assessmentId, '4');
    expect(result.displayCourseTitle, 'Where can I get some?');
    expect(result.videoTitle, 'Contrary to popular belief');
    expect(result.displayTitle, 'Pre Video Assess');
    expect(result.displayAssessmentType, 'Pre');
    expect(result.lastCompletedAt, DateTime(2026, 5, 17, 23, 23, 32));
    expect(result.timeTaken, '0 mins');
    expect(result.totalMarks, 20);
    expect(result.obtainedMarks, 4);
    expect(result.percentage, 20);
    expect(result.scoreLabel, '4/20');
  });
}
