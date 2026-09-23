import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env_config.dart';
import '../constants/app_constants.dart';
import '../../features/auth/data/auth_api_paths.dart';
import '../../features/auth/data/auth_token_store.dart';
import 'api_exception.dart';
import 'api_log_interceptor.dart';
import 'api_result.dart';
import 'mock_api_interceptor.dart';

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  return AuthTokenStore();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final store = ref.watch(authTokenStoreProvider);
  return ApiClient(tokenStore: store);
});

class ApiClient {
  ApiClient({
    Dio? dio,
    bool? useMockApi,
    MockApiInterceptor? mockInterceptor,
    AuthTokenStore? tokenStore,
  })  : _tokenStore = tokenStore,
        _dio = dio ??
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
        onRequest: (options, handler) async {
          final skipAuth = options.extra['skipAuth'] == true;
          final store = _tokenStore;
          if (!skipAuth && store != null) {
            final token = await store.readAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final store = _tokenStore;
          if (error.response?.statusCode == 401 &&
              store != null &&
              error.requestOptions.extra['retried'] != true &&
              error.requestOptions.extra['skipAuth'] != true) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.extra['retried'] = true;
              final token = await store.readAccessToken();
              if (token != null && token.isNotEmpty) {
                opts.headers['Authorization'] = 'Bearer $token';
              }
              try {
                final response = await _dio.fetch<dynamic>(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );

    if (enableMock) {
      _dio.interceptors.add(mockInterceptor ?? MockApiInterceptor());
    }
  }

  final Dio _dio;
  final AuthTokenStore? _tokenStore;
  bool _refreshing = false;

  Dio get dio => _dio;

  Future<bool> _tryRefresh() async {
    final store = _tokenStore;
    if (store == null || _refreshing) return false;
    final refresh = await store.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    _refreshing = true;
    try {
      final bare = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          headers: const {
            Headers.acceptHeader: Headers.jsonContentType,
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
        ),
      );
      final response = await bare.post<dynamic>(
        AuthApiPaths.refresh,
        data: {'refresh': refresh},
      );
      final data = response.data;
      if (data is! Map) return false;
      final access = (data['access'] as String?)?.trim() ?? '';
      if (access.isEmpty) return false;
      await store.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      return true;
    } catch (_) {
      await store.clear();
      return false;
    } finally {
      _refreshing = false;
    }
  }

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
    Map<String, dynamic>? extra,
    required T Function(dynamic data) parser,
  }) async {
    return _request(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: extra == null ? null : Options(extra: extra),
      ),
      parser,
    );
  }

  Future<ApiResult<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) parser,
  }) async {
    return _request(
      () => _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: extra == null ? null : Options(extra: extra),
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
        message: _messageFromBody(error) ?? exception.message,
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

  String? _messageFromBody(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is String && err.trim().isNotEmpty) return err.trim();
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return '${first.first}';
        if (first is String) return first;
      }
    }
    return null;
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
