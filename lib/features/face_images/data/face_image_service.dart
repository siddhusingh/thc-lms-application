import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../../models/face_image_state.dart';

class FaceImageService {
  FaceImageService(this._apiClient, this._sessionStore);

  final ApiClient _apiClient;
  final SecureSessionStore _sessionStore;

  Future<FaceImageState> fetchFaceImages() async {
    await _ensureSession();
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.faceImages,
    );
    return _parseState(response.data ?? {});
  }

  Future<FaceImageState> uploadFaceImage({
    required FaceImageSlot slot,
    required File file,
  }) async {
    await _ensureSession();
    final formData = FormData.fromMap({
      'face': slot.apiValue,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: _fileName(file),
      ),
    });
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.faceImages,
      data: formData,
    );
    return _parseState(response.data ?? {});
  }

  Future<void> _ensureSession() async {
    final token = await _sessionStore.readAccessToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        'You are not signed in. Please log in again.',
        statusCode: 401,
      );
    }
  }

  FaceImageState _parseState(Map<String, dynamic> response) {
    final payload = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    return FaceImageState.fromJson(payload);
  }

  String _fileName(File file) {
    final segments = file.uri.pathSegments;
    if (segments.isEmpty || segments.last.trim().isEmpty) {
      return 'face-image.jpg';
    }
    return segments.last;
  }
}
