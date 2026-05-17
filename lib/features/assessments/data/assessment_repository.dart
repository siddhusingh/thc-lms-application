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
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.startAssessment(id),
    );
    final data = response.data ?? {};
    final payload = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return AssessmentAttemptModel.fromJson(payload);
  }

  Future<Map<String, dynamic>> submitAssessment(
    String attemptId,
    Map<String, String> answers,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.submitAssessment(attemptId),
      data: {'answers': answers},
    );
    return response.data ?? {};
  }
}
