import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../models/dashboard_model.dart';

class DashboardRepository {
  DashboardRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardModel> fetchDashboard() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.dashboard,
    );
    final data = response.data ?? {};
    final payload = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return DashboardModel.fromJson(payload);
  }
}
