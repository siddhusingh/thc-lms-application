import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../models/user_model.dart';

class ProfileRepository {
  ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UserModel> fetchProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.profile,
    );
    final data = response.data ?? {};
    final payload = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return UserModel.fromJson(payload);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _apiClient.post<void>(
      ApiEndpoints.changePassword,
      data: {'current_password': currentPassword, 'password': newPassword},
    );
  }

  Future<UserModel> updateProfile({
    required String name,
    required String mobile,
    required String aadhaarNumber,
    required String address,
    required String email,
    required String dateOfBirth,
    required String panNumber,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.profile,
      data: {
        'name': name,
        'mobile': mobile,
        'adhaar_no': aadhaarNumber,
        'address': address,
        'email': email,
        'date_of_birth': dateOfBirth,
        'pan_no': panNumber,
      },
    );
    final data = response.data ?? {};
    final payload = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return UserModel.fromJson(payload);
  }

  Future<String> uploadProfileImage(Uint8List bytes) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.profileImage,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'profile-image.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      }),
    );
    final data = response.data ?? {};
    final payload = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    final imageUrl = payload['profile_image_url']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) {
      throw const FormatException('Profile image URL missing from response.');
    }
    return imageUrl;
  }
}
