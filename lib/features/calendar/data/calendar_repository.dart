import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../models/calendar_model.dart';

class CalendarRepository {
  CalendarRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<CalendarModel> fetchCalendar() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.calendar,
    );
    return CalendarModel.fromJson(response.data ?? {});
  }
}
