import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_config.dart';
import '../../../models/assessment_model.dart';
import '../../../models/paginated_response.dart';

class AssessmentRepository {
  AssessmentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<AssessmentModel>> fetchAssessments({
    int page = 1,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.assessments,
      queryParameters: {'page': page, 'per_page': AppConfig.pageSize},
    );
    return PaginatedResponse.fromJson(
      response.data ?? {},
      AssessmentModel.fromJson,
    );
  }

  Future<AssessmentAttemptModel> startAssessment(String id) async {
    if (kDebugMode) {
      debugPrint('Assessment start request: assessment_id=$id');
    }
    final startResponse = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.startAssessment(id),
      data: {'assessment_id': id},
    );
    final startData = startResponse.data ?? {};
    if (kDebugMode) {
      debugPrint('Assessment start response: $startData');
    }
    final startPayload = startData['data'] is Map<String, dynamic>
        ? startData['data'] as Map<String, dynamic>
        : startData;
    final startedAttempt = AssessmentAttemptModel.fromJson(startPayload);

    if (startedAttempt.questions.isNotEmpty) {
      return startedAttempt;
    }

    final questionAttempt = await fetchAssessmentQuestion(
      id,
      attemptId: startedAttempt.attemptId,
    );

    return startedAttempt.copyWith(
      attemptId: startedAttempt.attemptId.isNotEmpty
          ? startedAttempt.attemptId
          : questionAttempt.attemptId,
      questions: questionAttempt.questions,
      durationSeconds: startedAttempt.durationSeconds > 0
          ? startedAttempt.durationSeconds
          : questionAttempt.durationSeconds,
      totalQuestions: questionAttempt.totalQuestions,
      currentNumber: questionAttempt.currentNumber,
      nextQuestionId: questionAttempt.nextQuestionId,
      isLast: questionAttempt.isLast,
    );
  }

  Future<AssessmentAttemptModel> fetchAssessmentQuestion(
    String assessmentId, {
    String? attemptId,
    String? questionId,
  }) async {
    if (kDebugMode) {
      debugPrint(
        'Assessment question request: '
        'assessment_id=$assessmentId, '
        'attempt_id=$attemptId, '
        'question_id=$questionId',
      );
    }
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.assessment(assessmentId),
      queryParameters: {
        'assessment_id': assessmentId,
        if (attemptId != null && attemptId.isNotEmpty)
          'attempt_id': attemptId,
        if (questionId != null && questionId.isNotEmpty)
          'question_id': questionId,
      },
    );
    final data = response.data ?? {};
    if (kDebugMode) {
      debugPrint('Assessment question response: $data');
    }
    final payload = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return AssessmentAttemptModel.fromJson(payload);
  }

  Future<void> saveAssessmentAnswer({
    required String attemptId,
    required String questionId,
    required String answer,
  }) async {
    final payload = {
      'attempt_id': attemptId,
      'question_id': questionId,
      'answer': answer,
    };
    if (kDebugMode) {
      debugPrint('Assessment answer request: $payload');
    }
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.answerAssessment,
      data: payload,
    );
    if (kDebugMode) {
      debugPrint('Assessment answer response: ${response.data ?? {}}');
    }
  }

  Future<Map<String, dynamic>> submitAssessment(
    String assessmentId,
    String attemptId,
    Map<String, String> answers,
  ) async {
    final payload = {
      'assessment_id': assessmentId,
      if (attemptId.isNotEmpty) 'attempt_id': attemptId,
      'answers': answers,
    };
    if (kDebugMode) {
      debugPrint(
        'Assessment finish request: '
        'assessment_id=$assessmentId, '
        'attempt_id=$attemptId, '
        'answers=$answers',
      );
    }
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.submitAssessment(attemptId),
      data: payload,
    );
    final data = response.data ?? {};
    if (kDebugMode) {
      debugPrint('Assessment finish response: $data');
    }
    return data;
  }
}
