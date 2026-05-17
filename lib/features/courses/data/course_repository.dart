import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_config.dart';
import '../../../models/course_model.dart';
import '../../../models/course_player_model.dart';
import '../../../models/paginated_response.dart';

class CourseRepository {
  CourseRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<CourseModel>> fetchCourses({
    int page = 1,
    String? search,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.courses,
      queryParameters: {
        'page': page,
        'per_page': AppConfig.pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return PaginatedResponse.fromJson(
      response.data ?? {},
      CourseModel.fromJson,
    );
  }

  Future<CourseDetailModel> fetchCourse(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.course(id),
      queryParameters: {'course_id': id},
    );
    final data = response.data ?? {};
    final payload = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    final course = payload['course'] is Map<String, dynamic>
        ? payload['course'] as Map<String, dynamic>
        : payload;
    final videos = payload['videos'] is List ? payload['videos'] as List : [];
    return CourseDetailModel.fromJson({
      ...course,
      'id': course['id'] ?? course['_id'] ?? id,
      'modules': [
        {'id': 'playlist', 'title': 'Lessons', 'lessons': videos},
      ],
    });
  }

  Future<CoursePlaylistResponse> fetchCoursePlaylist(String courseId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.coursePlaylist,
      queryParameters: {'course_id': courseId},
    );
    return CoursePlaylistResponse.fromJson(response.data ?? {});
  }

  Future<VideoProgressResponse> fetchVideoProgress({
    required String courseId,
    required String videoId,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.videoProgress,
      queryParameters: {'course_id': courseId, 'video_id': videoId},
    );
    return VideoProgressResponse.fromJson(response.data ?? {});
  }

  Future<SaveVideoProgressResponse> saveVideoProgress({
    required String courseId,
    required String videoId,
    required int watchedSeconds,
    required int durationSeconds,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.videoProgress,
      data: {
        'course_id': courseId,
        'video_id': videoId,
        'watched_seconds': watchedSeconds,
        'duration': durationSeconds,
      },
    );
    return SaveVideoProgressResponse.fromJson(response.data ?? {});
  }

  Future<VideoAssessmentCheckResponse> checkVideoAssessment({
    required String courseId,
    required String videoId,
    required AssessmentType assessmentType,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.checkVideoAssessment,
      data: {
        'course_id': courseId,
        'video_id': videoId,
        'assessment_type': assessmentType.apiValue,
      },
    );
    return VideoAssessmentCheckResponse.fromJson(response.data ?? {});
  }

  Future<CourseAssessmentCheckResponse> checkCourseAssessment(
    String courseId,
    AssessmentType assessmentType,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.checkCourseAssessment,
      data: {'course_id': courseId, 'assessment_type': assessmentType.apiValue},
    );
    return CourseAssessmentCheckResponse.fromJson(response.data ?? {});
  }
}
