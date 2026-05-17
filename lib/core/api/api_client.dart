import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../constants/app_config.dart';
import '../storage/secure_session_store.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._sessionStore)
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.requestTimeout,
          receiveTimeout: AppConfig.requestTimeout,
          sendTimeout: AppConfig.requestTimeout,
          headers: {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _sessionStore.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !_isRefreshRequest(error.requestOptions)) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              try {
                final response = await dio.fetch<dynamic>(error.requestOptions);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.reject(retryError);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final SecureSessionStore _sessionStore;
  final Dio dio;
  Future<bool>? _refreshFuture;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _guard(() => dio.get<T>(path, queryParameters: queryParameters));
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard(
      () => dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> put<T>(String path, {Object? data}) {
    return _guard(() => dio.put<T>(path, data: data));
  }

  Future<Response<T>> delete<T>(String path, {Object? data}) {
    return _guard(() => dio.delete<T>(path, data: data));
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  ApiException _mapDioException(DioException error) {
    final response = error.response;
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        data['message']?.toString() ??
            'Something went wrong. Please try again.',
        statusCode: response?.statusCode,
        errors: data['errors'] is Map<String, dynamic>
            ? data['errors'] as Map<String, dynamic>
            : null,
      );
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return ApiException(
        'Network unavailable. Check your connection and try again.',
      );
    }
    return ApiException(
      error.message ?? 'Something went wrong. Please try again.',
      statusCode: response?.statusCode,
    );
  }

  bool _isRefreshRequest(RequestOptions options) =>
      options.path.contains(ApiEndpoints.refreshToken);

  Future<bool> _refreshToken() {
    _refreshFuture ??= _doRefresh().whenComplete(() => _refreshFuture = null);
    return _refreshFuture!;
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _sessionStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );
      final data = response.data ?? {};
      final accessToken =
          data['access_token']?.toString() ?? data['token']?.toString();
      final nextRefreshToken = data['refresh_token']?.toString();
      if (accessToken == null || accessToken.isEmpty) {
        return false;
      }
      await _sessionStore.saveTokens(
        accessToken: accessToken,
        refreshToken: nextRefreshToken ?? refreshToken,
      );
      return true;
    } catch (_) {
      await _sessionStore.clear();
      return false;
    }
  }
}
