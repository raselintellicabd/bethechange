import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  final String message;
  final int? statusCode;
  final Object? originalError;

  factory ApiException.fromDioException(DioException error) {
    final statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException(
          message: 'Connection timed out. Please try again.',
          statusCode: statusCode,
          originalError: error,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Unable to connect. Check your internet connection.',
          statusCode: statusCode,
          originalError: error,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          message: _messageForStatusCode(statusCode),
          statusCode: statusCode,
          originalError: error,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled.',
          statusCode: statusCode,
          originalError: error,
        );
      case DioExceptionType.badCertificate:
        return ApiException(
          message: 'Secure connection failed.',
          statusCode: statusCode,
          originalError: error,
        );
      case DioExceptionType.unknown:
        return ApiException(
          message: 'Something went wrong. Please try again.',
          statusCode: statusCode,
          originalError: error,
        );
    }
  }

  static String _messageForStatusCode(int? statusCode) {
    return switch (statusCode) {
      400 => 'Invalid request. Please check your input.',
      401 => 'You need to sign in to continue.',
      403 => 'You do not have permission to do that.',
      404 => 'The requested resource was not found.',
      408 => 'Request timed out. Please try again.',
      429 => 'Too many requests. Please wait and try again.',
      500 => 'Server error. Please try again later.',
      502 || 503 || 504 => 'Service temporarily unavailable.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
