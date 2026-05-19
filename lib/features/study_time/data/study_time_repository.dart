import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../models/study_time_model.dart';

class StudyTimeRepository {
  StudyTimeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<StudyTimeModel> fetchStudyTime() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.studyTime,
    );
    return StudyTimeModel.fromJson(response.data ?? {});
  }
}
