import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_config.dart';
import '../../../models/certificate_model.dart';
import '../../../models/paginated_response.dart';

class CertificateRepository {
  CertificateRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<CertificateModel>> fetchCertificates({
    int page = 1,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.certificates,
      queryParameters: {'page': page, 'per_page': AppConfig.pageSize},
    );
    return PaginatedResponse.fromJson(
      response.data ?? {},
      CertificateModel.fromJson,
    );
  }
}
