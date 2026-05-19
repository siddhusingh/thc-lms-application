import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../models/learning_path_model.dart';

class LearningPathRepository {
  LearningPathRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<LearningPathModel> fetchLearningPath() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.learningPath,
    );
    return LearningPathModel.fromJson(response.data ?? {});
  }
}
