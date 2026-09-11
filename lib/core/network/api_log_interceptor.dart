import 'dart:convert';

import 'package:dio/dio.dart';

/// Prints each Dio call in the debug console: request, success, or failure.
class ApiLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    _write('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final status = response.statusCode ?? 0;
    _write(
      '✓ $status ${response.requestOptions.method} ${response.requestOptions.uri}'
      '${_elapsed(response.requestOptions)}',
    );
    _writeBody(response.data);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    _write(
      '✗ ${status ?? 'FAILED'} ${err.requestOptions.method} '
      '${err.requestOptions.uri}${_elapsed(err.requestOptions)}',
    );
    final message = err.message?.trim();
    if (message != null && message.isNotEmpty) {
      _write(message);
    }
    _writeBody(err.response?.data);
    handler.next(err);
  }

  static const _startedAtKey = 'apiLogStartedAt';

  static String _elapsed(RequestOptions options) {
    final started = options.extra[_startedAtKey];
    if (started is! DateTime) return '';
    final ms = DateTime.now().difference(started).inMilliseconds;
    return ' (${ms}ms)';
  }

  static void _writeBody(Object? data) {
    if (data == null) return;
    final text = _format(data);
    if (text.isEmpty) return;
    for (final line in text.split('\n')) {
      _write(line);
    }
  }

  static String _format(Object data) {
    if (data is String) return data;
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return '$data';
    }
  }

  static void _write(String message) {
    // print, not debugPrint: debugPrint throttles and drops the status/body.
    // ignore: avoid_print
    print('[API] $message');
  }
}
