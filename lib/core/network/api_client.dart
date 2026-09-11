import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env_config.dart';
import '../constants/app_constants.dart';
import 'api_exception.dart';
import 'api_log_interceptor.dart';
import 'api_result.dart';
import 'mock_api_interceptor.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  ApiClient({
    Dio? dio,
    bool? useMockApi,
    MockApiInterceptor? mockInterceptor,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _safeBaseUrl(),
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
                sendTimeout: AppConstants.sendTimeout,
                headers: const {
                  Headers.acceptHeader: Headers.jsonContentType,
                  Headers.contentTypeHeader: Headers.jsonContentType,
                },
              ),
            ) {
    final enableMock = useMockApi ?? _safeUseMockApi();

    if (kDebugMode) {
      _dio.interceptors.add(ApiLogInterceptor());
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Auth token injection will be added when auth is introduced.
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );

    if (enableMock) {
      _dio.interceptors.add(mockInterceptor ?? MockApiInterceptor());
    }
  }

  final Dio _dio;

  Dio get dio => _dio;

  static String _safeBaseUrl() {
    try {
      return EnvConfig.apiBaseUrl;
    } catch (_) {
      return 'https://mock.local';
    }
  }

  static bool _safeUseMockApi() {
    try {
      return EnvConfig.useMockApi;
    } catch (_) {
      return true;
    }
  }

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) parser,
  }) async {
    return _request(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
      parser,
    );
  }

  Future<ApiResult<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) parser,
  }) async {
    return _request(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
      parser,
    );
  }

  Future<ApiResult<T>> _request<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic data) parser,
  ) async {
    try {
      final response = await call();
      return ApiSuccess(parser(response.data));
    } on DioException catch (error) {
      final exception = ApiException.fromDioException(error);
      return ApiFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        error: exception,
      );
    } catch (error) {
      return ApiFailure(
        message: 'Something went wrong. Please try again.',
        error: error,
      );
    }
  }

  /// Placeholder health check used to verify networking wiring.
  Future<ApiResult<Map<String, dynamic>>> healthCheck() {
    return get(
      '/health',
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        return <String, dynamic>{'raw': data};
      },
    );
  }
}
