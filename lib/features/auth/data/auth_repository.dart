import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../../models/user_model.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._sessionStore);

  final ApiClient _apiClient;
  final SecureSessionStore _sessionStore;

  Future<UserModel> login({
    required String email,
    required String password,
    bool rememberLogin = true,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return _persistAuthResponse(
      response.data ?? {},
      rememberLogin: rememberLogin,
    );
  }

  Future<UserModel> register(Map<String, dynamic> payload) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: payload,
    );
    return _persistAuthResponse(response.data ?? {});
  }

  Future<void> forgotPassword(String email) {
    return _apiClient.post<void>(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  Future<void> verifyOtp({required String email, required String otp}) {
    return _apiClient.post<void>(
      ApiEndpoints.verifyOtp,
      data: {'email': email, 'otp': otp},
    );
  }

  Future<UserModel?> currentUser() async {
    final token = await _sessionStore.readAccessToken();
    if (token == null || token.isEmpty) return null;
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.me,
    );
    final data = response.data ?? {};
    return UserModel.fromJson(_unwrapUser(data));
  }

  Future<bool> hasStoredSession() async {
    final token = await _sessionStore.readAccessToken();
    final remember = await _sessionStore.readRememberLogin();
    return remember && token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post<void>(ApiEndpoints.logout);
    } finally {
      await _sessionStore.clear();
    }
  }

  Future<UserModel> registerFace(File image) async {
    final form = await _faceFormData(image);
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.faceRegister,
      data: form,
    );
    return UserModel.fromJson(_unwrapUser(response.data ?? {}));
  }

  Future<UserModel> verifyFace(File image, {String? context}) async {
    try {
      final form = await _faceFormData(image, context: context);
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.faceVerify,
        data: form,
      );
      return UserModel.fromJson(_unwrapUser(response.data ?? {}));
    } on ApiException catch (exception) {
      if (context == null || !_isLegacyUnknownMethod(exception)) {
        rethrow;
      }

      final legacyForm = await _faceFormData(image);
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.faceVerify,
        data: legacyForm,
      );
      return UserModel.fromJson(_unwrapUser(response.data ?? {}));
    }
  }

  Future<UserModel> _persistAuthResponse(
    Map<String, dynamic> data, {
    bool rememberLogin = true,
  }) async {
    final accessToken = _extractToken(data, const [
      'access_token',
      'token',
      'auth_token',
      'bearer_token',
    ]);
    if (accessToken != null && accessToken.isNotEmpty) {
      await _sessionStore.saveTokens(
        accessToken: accessToken,
        refreshToken: _extractToken(data, const ['refresh_token']),
        rememberLogin: rememberLogin,
      );
    }
    return UserModel.fromJson(_unwrapUser(data));
  }

  Map<String, dynamic> _unwrapUser(Map<String, dynamic> data) {
    for (final key in const ['user', 'student', 'profile']) {
      final value = data[key];
      if (value is Map<String, dynamic>) return value;
    }
    for (final key in const ['data', 'result', 'response']) {
      final value = data[key];
      if (value is Map<String, dynamic>) return _unwrapUser(value);
    }
    return data;
  }

  String? _extractToken(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return _normalizeToken(value);
      }
    }
    for (final key in const [
      'data',
      'result',
      'response',
      'auth',
      'authorization',
      'authorisation',
    ]) {
      final value = data[key];
      if (value is Map<String, dynamic>) {
        final token = _extractToken(value, keys);
        if (token != null && token.isNotEmpty) return token;
      }
    }
    return null;
  }

  String _normalizeToken(String token) {
    return token.replaceFirst(RegExp(r'^Bearer\s+', caseSensitive: false), '');
  }

  bool _isLegacyUnknownMethod(ApiException exception) {
    return exception.message.trim().toLowerCase() == 'unknown method';
  }

  Future<FormData> _faceFormData(File image, {String? context}) async {
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    final compressed = decoded == null
        ? bytes
        : img.encodeJpg(img.copyResize(decoded, width: 960), quality: 82);
    final fields = <String, Object>{
      'face_image': MultipartFile.fromBytes(
        compressed,
        filename: 'face.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      ),
    };
    if (context != null) {
      fields['context'] = context;
    }
    return FormData.fromMap(fields);
  }
}
