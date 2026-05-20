import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../models/analytics_model.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AnalyticsModel> fetchAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.analytics,
      queryParameters: {
        'start_date': _formatApiDate(startDate),
        'end_date': _formatApiDate(endDate),
      },
    );
    return AnalyticsModel.fromJson(response.data ?? {});
  }
}

String _formatApiDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
}
