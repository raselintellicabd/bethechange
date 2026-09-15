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
          message: _messageFromBody(error.response?.data) ??
              (error.message?.trim().isNotEmpty == true
                  ? error.message!.trim()
                  : _messageForStatusCode(statusCode)),
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

  static String? _messageFromBody(Object? data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
      if (detail is List && detail.isNotEmpty) {
        return detail.map((e) => '$e').join(' ');
      }
      final nonField = data['non_field_errors'];
      if (nonField is List && nonField.isNotEmpty) {
        return nonField.map((e) => '$e').join(' ');
      }
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          return value.map((e) => '$e').join(' ');
        }
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    if (data is List && data.isNotEmpty) {
      return data.map((e) => '$e').join(' ');
    }
    return null;
  }

  static String _messageForStatusCode(int? statusCode) {
    return switch (statusCode) {
      400 => 'Invalid request. Please check your input.',
      401 => 'You need to sign in to continue.',
      403 => 'You do not have permission to do that.',
      404 => 'The requested resource was not found.',
      408 => 'Request timed out. Please try again.',
      409 => 'That request could not be completed. Please try again.',
      429 => 'Too many requests. Please wait and try again.',
      500 => 'Server error. Please try again later.',
      502 || 503 || 504 => 'Service temporarily unavailable.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
