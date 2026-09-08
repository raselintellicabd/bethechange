import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../config/env_config.dart';
import 'api_paths.dart';
import 'mock_api_assets.dart';

/// Serves local JSON (and in-memory POST handlers) as if they were HTTP APIs.
///
/// Enabled when [EnvConfig.useMockApi] is true. Repositories always call
/// [ApiClient] paths; flipping mock off points the same code at Django REST.
class MockApiInterceptor extends Interceptor {
  MockApiInterceptor({
    AssetBundle? bundle,
    DateTime? now,
    this.readDelay = Duration.zero,
    this.writeDelay = Duration.zero,
    this._chatbotApiKey,
  })  : _bundle = bundle ?? rootBundle,
        _now = now ?? DateTime.now();

  final AssetBundle _bundle;
  final DateTime _now;
  final Duration readDelay;
  final Duration writeDelay;
  final String? _chatbotApiKey;

  final Map<String, dynamic> _jsonCache = {};
  int _contactCounter = 0;
  int _conversationCounter = 0;
  int _confirmationCounter = 1000;

  DateTime get _today => DateTime(_now.year, _now.month, _now.day);

  String get _resolvedChatbotKey {
    final injected = _chatbotApiKey;
    if (injected != null) return injected;
    try {
      return EnvConfig.chatbotApiKey;
    } catch (_) {
      return 'placeholder';
    }
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _handle(options).then((response) {
      handler.resolve(response);
    }).catchError((Object error, StackTrace stackTrace) {
      if (error is _MockHttpError) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: error.statusCode,
              data: {'message': error.message},
            ),
            type: DioExceptionType.badResponse,
            message: error.message,
            stackTrace: stackTrace,
          ),
        );
        return;
      }
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          type: DioExceptionType.unknown,
          stackTrace: stackTrace,
          message: error.toString(),
        ),
      );
    });
  }

  Future<Response<dynamic>> _handle(RequestOptions options) async {
    final method = options.method.toUpperCase();
    final path = _normalizePath(options.path);

    if (method == 'GET') {
      await Future<void>.delayed(readDelay);
      final data = await _handleGet(path, options.queryParameters);
      return Response<dynamic>(
        requestOptions: options,
        data: data,
        statusCode: 200,
      );
    }

    if (method == 'POST') {
      await Future<void>.delayed(writeDelay);
      final data = await _handlePost(path, options.data);
      return Response<dynamic>(
        requestOptions: options,
        data: data,
        statusCode: 200,
      );
    }

    throw _MockHttpError(405, 'Method $method is not supported in mock API.');
  }

  Future<Object?> _handleGet(
    String path,
    Map<String, dynamic> query,
  ) async {
    switch (path) {
      case ApiPaths.about:
        return _loadObject(MockApiAssets.about);
      case ApiPaths.conditions:
        return _loadObject(MockApiAssets.conditions);
      case ApiPaths.services:
        return _loadObject(MockApiAssets.services);
      case ApiPaths.blog:
        return _loadObject(MockApiAssets.blog);
      case ApiPaths.faq:
        return _loadObject(MockApiAssets.faq);
      case ApiPaths.clinic:
        return _loadObject(MockApiAssets.clinic);
      case ApiPaths.home:
        return _loadObject(MockApiAssets.home);
      case ApiPaths.patients:
        return _loadObject(MockApiAssets.patients);
      case ApiPaths.chatbotConfig:
        return _chatbotConfigPayload();
      case ApiPaths.appointmentsAvailability:
        return _availableDatesPayload(query);
      case ApiPaths.appointmentsSlots:
        return _slotsPayload(query);
    }

    final conditionId = _matchId(path, ApiPaths.conditions);
    if (conditionId != null) {
      return _itemById(
        MockApiAssets.conditions,
        listKey: 'conditions',
        id: conditionId,
        notFoundLabel: 'Condition',
      );
    }

    final serviceId = _matchId(path, ApiPaths.services);
    if (serviceId != null) {
      return _itemById(
        MockApiAssets.services,
        listKey: 'services',
        id: serviceId,
        notFoundLabel: 'Service',
      );
    }

    final articleId = _matchId(path, ApiPaths.blog);
    if (articleId != null) {
      return _itemById(
        MockApiAssets.blog,
        listKey: 'articles',
        id: articleId,
        notFoundLabel: 'Article',
      );
    }

    throw _MockHttpError(404, 'No mock handler for GET $path.');
  }

  Future<Object?> _handlePost(String path, Object? rawData) async {
    final data = _asMap(rawData);

    switch (path) {
      case ApiPaths.contact:
        return _submitContact(data);
      case ApiPaths.chatbotMessage:
        return _chatbotReply(data);
      case ApiPaths.appointments:
        return _bookAppointment(data);
    }

    throw _MockHttpError(404, 'No mock handler for POST $path.');
  }

  Future<Map<String, dynamic>> _submitContact(Map<String, dynamic> data) async {
    final name = (data['name'] as String?)?.trim() ?? '';
    final email = (data['email'] as String?)?.trim() ?? '';
    final phone = (data['phone'] as String?)?.trim() ?? '';
    final subject = (data['subject'] as String?)?.trim() ?? '';
    final message = (data['message'] as String?)?.trim() ?? '';

    final haystack = '$subject $message'.toLowerCase();
    if (haystack.contains('force error')) {
      throw const _MockHttpError(
        503,
        'Unable to send your message. Please try again.',
      );
    }

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        subject.isEmpty ||
        message.isEmpty) {
      throw const _MockHttpError(400, 'All contact fields are required.');
    }

    return {
      'id': 'contact-${++_contactCounter}',
      'status': 'received',
    };
  }

  Future<Map<String, dynamic>> _chatbotReply(Map<String, dynamic> data) async {
    if (_resolvedChatbotKey.trim().isEmpty) {
      throw const _MockHttpError(401, 'Chatbot API key is missing.');
    }

    final message = (data['message'] as String?)?.trim() ?? '';
    final conversationId = (data['conversationId'] as String?)?.trim();

    if (message.isEmpty) {
      throw const _MockHttpError(400, 'Message cannot be empty.');
    }
    if (message.toLowerCase().contains('force error')) {
      throw const _MockHttpError(
        503,
        'Unable to reach the chatbot. Please try again.',
      );
    }

    final id = (conversationId != null && conversationId.isNotEmpty)
        ? conversationId
        : 'mock-convo-${++_conversationCounter}';

    return {
      'reply': await _replyFor(message),
      'conversationId': id,
    };
  }

  Future<Map<String, dynamic>> _bookAppointment(
    Map<String, dynamic> data,
  ) async {
    final patient = _asMap(data['patient']);
    final notes = (patient['notes'] as String?)?.trim().toLowerCase() ?? '';
    if (notes == 'force error') {
      throw const _MockHttpError(
        409,
        'That time slot was just taken. Please choose another time.',
      );
    }

    _confirmationCounter += 1;
    return {
      'confirmationId': 'BTC-$_confirmationCounter',
      'bookedAt': _now.toIso8601String(),
      'request': data,
    };
  }

  Future<Map<String, dynamic>> _availableDatesPayload(
    Map<String, dynamic> query,
  ) async {
    final year = int.tryParse('${query['year'] ?? ''}');
    final month = int.tryParse('${query['month'] ?? ''}');
    if (year == null || month == null || month < 1 || month > 12) {
      throw const _MockHttpError(
        400,
        'year and month query parameters are required.',
      );
    }

    final config = await _appointmentConfig();
    final availableWeekdays =
        (config['availableWeekdays'] as List<dynamic>? ?? const [1, 2, 3, 4, 5])
            .map((e) => e as int)
            .toSet();

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final dates = <String>[];
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isFutureOrToday = !date.isBefore(_today);
      if (availableWeekdays.contains(date.weekday) && isFutureOrToday) {
        dates.add(_dateKey(date));
      }
    }

    return {'dates': dates};
  }

  Future<Map<String, dynamic>> _slotsPayload(
    Map<String, dynamic> query,
  ) async {
    final rawDate = '${query['date'] ?? ''}';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) {
      throw const _MockHttpError(400, 'date query parameter is required.');
    }

    final normalized = DateTime(parsed.year, parsed.month, parsed.day);
    if (normalized.isBefore(_today)) {
      return {'slots': <Map<String, dynamic>>[]};
    }

    final config = await _appointmentConfig();
    final emptyWeekdays =
        (config['emptySlotWeekdays'] as List<dynamic>? ?? const [5])
            .map((e) => e as int)
            .toSet();
    if (emptyWeekdays.contains(normalized.weekday)) {
      return {'slots': <Map<String, dynamic>>[]};
    }

    final slotHours =
        (config['slotHours'] as List<dynamic>? ?? const [9, 10, 11, 13, 14, 15])
            .map((e) => e as int)
            .toList();

    final slots = slotHours.map((hour) {
      final dateTime = DateTime(
        normalized.year,
        normalized.month,
        normalized.day,
        hour,
      );
      final displayHour = hour > 12 ? hour - 12 : hour;
      final suffix = hour >= 12 ? 'PM' : 'AM';
      return {
        'id': '${_dateKey(normalized)}-$hour',
        'label': '$displayHour:00 $suffix',
        'dateTime': dateTime.toIso8601String(),
      };
    }).toList();

    return {'slots': slots};
  }

  Future<Map<String, dynamic>> _chatbotConfigPayload() async {
    final full = await _loadObject(MockApiAssets.chatbotReplies);
    return {
      'suggestions': full['suggestions'] ?? const <String>[],
      'disclaimer': full['disclaimer'] ?? '',
      'emptyPrompt': full['emptyPrompt'] ?? '',
    };
  }

  Future<String> _replyFor(String message) async {
    final lower = message.toLowerCase();
    final full = await _loadObject(MockApiAssets.chatbotReplies);
    final replies = full['replies'] as List<dynamic>? ?? const [];

    for (final entry in replies) {
      if (entry is! Map<String, dynamic>) continue;
      final keywords = (entry['keywords'] as List<dynamic>? ?? const [])
          .map((e) => '$e'.toLowerCase())
          .toList();
      for (final keyword in keywords) {
        if (lower.contains(keyword)) {
          return (entry['reply'] as String?)?.trim() ?? '';
        }
      }
    }

    return (full['defaultReply'] as String?)?.trim() ??
        'Thanks for your message.';
  }

  Future<Map<String, dynamic>> _appointmentConfig() {
    return _loadObject(MockApiAssets.appointmentConfig);
  }

  Future<Map<String, dynamic>> _itemById(
    String assetPath, {
    required String listKey,
    required String id,
    required String notFoundLabel,
  }) async {
    final root = await _loadObject(assetPath);
    final list = root[listKey] as List<dynamic>? ?? const [];
    for (final entry in list) {
      if (entry is Map<String, dynamic> && entry['id'] == id) {
        return entry;
      }
    }
    throw _MockHttpError(404, '$notFoundLabel "$id" was not found.');
  }

  Future<Map<String, dynamic>> _loadObject(String assetPath) async {
    final cached = _jsonCache[assetPath];
    if (cached is Map<String, dynamic>) {
      return Map<String, dynamic>.from(cached);
    }

    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Expected JSON object in $assetPath.');
    }
    _jsonCache[assetPath] = decoded;
    return Map<String, dynamic>.from(decoded);
  }

  static String _normalizePath(String path) {
    var cleaned = path.trim();
    if (cleaned.isEmpty) return '/';
    final uri = Uri.parse(cleaned);
    cleaned = uri.path;
    if (!cleaned.startsWith('/')) cleaned = '/$cleaned';
    if (cleaned.length > 1 && cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }

  static String? _matchId(String path, String prefix) {
    if (!path.startsWith('$prefix/')) return null;
    final id = path.substring(prefix.length + 1);
    if (id.isEmpty || id.contains('/')) return null;
    return Uri.decodeComponent(id);
  }

  static Map<String, dynamic> _asMap(Object? raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    }
    return {};
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _MockHttpError implements Exception {
  const _MockHttpError(this.statusCode, this.message);

  final int statusCode;
  final String message;
}
