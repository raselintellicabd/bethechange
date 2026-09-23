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
      handler.resolve(response, true);
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
          true,
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
        true,
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

    if (method == 'PATCH') {
      await Future<void>.delayed(writeDelay);
      final data = await _handlePatch(path, options.data);
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
        return _conditionsListPayload();
      case ApiPaths.services:
        return _servicesListPayload();
      case ApiPaths.blog:
        return _blogListPayload();
      case ApiPaths.faq:
        return _loadObject(MockApiAssets.faq);
      case ApiPaths.clinic:
        return _loadObject(MockApiAssets.clinic);
      case ApiPaths.home:
        return _loadObject(MockApiAssets.home);
      case ApiPaths.patients:
        return _loadObject(MockApiAssets.patients);
      case ApiPaths.contact:
        return _loadObject(MockApiAssets.contact);
      case ApiPaths.memberships:
        return _loadObject(MockApiAssets.memberships);
      case '/appointments/availability':
        return _availabilityWindowPayload(query);
      case ApiPaths.appointmentsQuote:
      case '/api/v1/appointments/quote':
        return {
          'ok': true,
          'list_amount_cents': 0,
          'discount_cents': 0,
          'payable_cents': 0,
          'discount_percent': 0,
          'used_complimentary': false,
          'pricing_note': 'Guest / free-tier rate (list price).',
          'list_amount_display': 'Free',
          'discount_display': '\$0',
          'payable_display': 'Free',
        };
      case '/api/v1/auth/patient/me':
      case '/api/v1/auth/patient/me/':
        return _mockPatientMe();
      case ApiPaths.appointmentsHistory:
      case '/api/v1/appointments/history':
        return {
          'results': [
            {
              'id': 1,
              'when': 'Sep 29, 2026 · 10:00 AM',
              'service': 'Consultation regarding Diabetes',
              'mode': 'Virtual',
              'status': 'Pending',
              'status_key': 'pending',
              'amount': '\$31.50',
            },
            {
              'id': 2,
              'when': 'Sep 29, 2026 · 11:00 AM',
              'service': 'Infrared Sauna 30 Minute Session',
              'mode': 'Virtual',
              'status': 'Pending',
              'status_key': 'pending',
              'amount': '\$58.50',
            },
            {
              'id': 3,
              'when': 'Sep 29, 2026 · 12:00 PM',
              'service': 'Frequency Specific Microcurrent',
              'mode': 'Virtual',
              'status': 'Pending',
              'status_key': 'pending',
              'amount': '—',
            },
          ],
        };
      case '/api/v1/book-online':
        return _bookOnlineCatalogPayload();
      case ApiPaths.chatbotConfig:
        return _chatbotConfigPayload();
    }

    final conditionId = _matchId(path, ApiPaths.conditions);
    if (conditionId != null) {
      return _itemById(
        MockApiAssets.conditions,
        listKey: 'conditions',
        id: conditionId,
        notFoundLabel: 'Condition',
        alternateIdKey: 'slug',
      );
    }

    final serviceId = _matchId(path, ApiPaths.services);
    if (serviceId != null) {
      return _itemById(
        MockApiAssets.services,
        listKey: 'services',
        id: serviceId,
        notFoundLabel: 'Service',
        alternateIdKey: 'slug',
      );
    }

    final aboutSlug = _matchId(path, ApiPaths.about);
    if (aboutSlug != null) {
      final pages = await _loadObject(MockApiAssets.aboutPages);
      final page = pages[aboutSlug];
      if (page is Map<String, dynamic>) return page;
      if (page is Map) return page.map((k, v) => MapEntry('$k', v));
      throw _MockHttpError(404, 'About page "$aboutSlug" was not found.');
    }

    final doctorId = _matchId(path, ApiPaths.doctors);
    if (doctorId != null) {
      return _itemById(
        MockApiAssets.doctors,
        listKey: 'doctors',
        id: doctorId,
        notFoundLabel: 'Doctor',
        alternateIdKey: 'slug',
      );
    }

    final articleId = _matchId(path, ApiPaths.blog);
    if (articleId != null) {
      return _itemById(
        MockApiAssets.blog,
        listKey: 'articles',
        id: articleId,
        notFoundLabel: 'Article',
        alternateIdKey: 'slug',
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
      case '/api/v1/appointments':
      case ApiPaths.appointmentsBook:
        return _bookAppointment(data);
      case ApiPaths.appointmentsPaymentSession:
        return {
          'ok': true,
          'provider': 'mock',
          'payment_session_id': 'pay_mock_${_confirmationCounter + 1}',
          'client_secret': 'secret_mock',
          'status': 'requires_payment',
          'amount_cents': 0,
          'amount_display': 'Free',
        };
      case ApiPaths.appointmentsPaymentConfirm:
        return {
          'ok': true,
          'provider': 'mock',
          'payment_session_id': data['payment_session_id'],
          'status': 'succeeded',
          'amount_cents': 0,
          'amount_display': 'Free',
        };
      case '/api/v1/auth/patient/login/':
      case '/api/v1/auth/patient/signup/':
        return {
          'ok': true,
          'access': 'mock_access',
          'refresh': 'mock_refresh',
          'user': {
            'id': 1,
            'email': data['email'] ?? 'guest@example.com',
            'first_name': data['first_name'] ?? 'Mock',
            'last_name': data['last_name'] ?? 'User',
            'phone': data['phone'] ?? '5555555555',
            'tier': 0,
            'tier_title': 'Free',
            'left_days': 0,
            'services_taken': 0,
            'complimentary_used': 0,
            'membership_active': false,
            'can_book_for_family': false,
          },
        };
      case '/api/v1/memberships/payment/session/':
        return {
          'ok': true,
          'payment_session_id': 'mem_mock_1',
          'client_secret': 'secret',
          'tier': data['tier'] ?? 1,
          'amount_cents': 2500,
          'amount_display': '\$25',
        };
      case '/api/v1/memberships/payment/confirm/':
        return {
          'ok': true,
          'tier': 1,
          'user': {
            'id': 1,
            'email': 'guest@example.com',
            'first_name': 'Mock',
            'last_name': 'User',
            'phone': '5555555555',
            'tier': 1,
            'tier_title': 'Standard Wellness Membership',
            'left_days': 120,
            'services_taken': 0,
            'complimentary_used': 0,
            'membership_active': true,
            'can_book_for_family': false,
          },
        };
    }

    throw _MockHttpError(404, 'No mock handler for POST $path.');
  }

  Future<Object?> _handlePatch(String path, Object? rawData) async {
    final data = _asMap(rawData);
    switch (path) {
      case '/api/v1/auth/patient/me':
      case '/api/v1/auth/patient/me/':
        return _mockPatientMe(
          email: '${data['email'] ?? 'guest@example.com'}',
          firstName: '${data['first_name'] ?? 'Mock'}',
          lastName: '${data['last_name'] ?? 'User'}',
          phone: '${data['phone'] ?? '5555555555'}',
        );
    }
    throw _MockHttpError(404, 'No mock handler for PATCH $path.');
  }

  Map<String, dynamic> _mockPatientMe({
    String email = 'guest@example.com',
    String firstName = 'Mock',
    String lastName = 'User',
    String phone = '5555555555',
  }) {
    return {
      'id': 1,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'tier': 2,
      'tier_title': 'Specialized Wellness Membership',
      'left_days': 29,
      'services_taken': 10,
      'complimentary_used': 2,
      'complimentary_allowance': 2,
      'membership_active': true,
      'membership_started_at': '2026-09-22',
      'membership_expires_at': '2026-10-22',
      'can_book_for_family': false,
      'upgrade_suggestion': {
        'current_tier': 2,
        'current_title': 'Specialized Wellness Membership',
        'next_tier': 3,
        'next_title': 'Family Wellness Membership',
        'message':
            "You're on Specialized Wellness Membership. Consider upgrading to Family Wellness Membership for more benefits.",
      },
    };
  }

  Future<Map<String, dynamic>> _submitContact(Map<String, dynamic> data) async {
    final name = '${data['name'] ?? ''}'.trim();
    final email = '${data['email'] ?? ''}'.trim();
    final phone = '${data['phone'] ?? ''}'.trim();
    final message = '${data['message'] ?? ''}'.trim();
    final category = '${data['category'] ?? 'services'}'.trim().toLowerCase();
    final doctorIdRaw = data['doctor_id'];
    final doctorId = doctorIdRaw is int
        ? doctorIdRaw
        : int.tryParse('${doctorIdRaw ?? ''}'.trim());

    if (message.toLowerCase().contains('force error')) {
      throw const _MockHttpError(
        503,
        'Unable to send your message. Please try again.',
      );
    }

    if (name.isEmpty || email.isEmpty || phone.isEmpty || message.isEmpty) {
      throw const _MockHttpError(400, 'All contact fields are required.');
    }

    if (category == 'doctors' && doctorId == null) {
      throw const _MockHttpError(400, 'Please select a doctor.');
    }

    final id = ++_contactCounter;
    return {
      'id': '$id',
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
    final service = '${data['service'] ?? ''}'.trim();
    final fullName = '${data['full_name'] ?? ''}'.trim();
    final email = '${data['email'] ?? ''}'.trim();
    final phone = '${data['phone'] ?? ''}'.trim();
    final mode = '${data['consultation_mode'] ?? ''}'.trim();
    final startsAt = '${data['starts_at'] ?? ''}'.trim();
    final endsAt = '${data['ends_at'] ?? ''}'.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        service.isEmpty ||
        mode.isEmpty ||
        startsAt.isEmpty ||
        endsAt.isEmpty) {
      throw const _MockHttpError(400, 'Missing required appointment fields.');
    }

    if (phone.toLowerCase().contains('force') ||
        fullName.toLowerCase() == 'force error') {
      throw const _MockHttpError(
        400,
        'That time slot was just taken. Please choose another time.',
      );
    }

    _confirmationCounter += 1;
    return {
      'id': _confirmationCounter,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'service': service,
      'consultation_mode': mode,
      'meet_link': '',
      'starts_at': startsAt,
      'ends_at': endsAt,
      'status': 'pending',
      'created_at': _now.toIso8601String(),
      'updated_at': _now.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _availabilityWindowPayload(
    Map<String, dynamic> query,
  ) async {
    final service = '${query['service'] ?? ''}'.trim();
    final today = _today;
    final days = <String, List<Map<String, dynamic>>>{};

    for (var offset = 0; offset <= 14; offset++) {
      final day = today.add(Duration(days: offset));
      final key = _dateKey(day);
      if (day.weekday > DateTime.friday) {
        days[key] = const [];
        continue;
      }

      final slots = <Map<String, dynamic>>[];
      for (var minutes = 10 * 60; minutes <= 16 * 60 + 30; minutes += 30) {
        var state = 'available';
        // Fridays: no open slots (busy) so calendar disables them.
        if (day.weekday == DateTime.friday) {
          state = 'busy';
        }
        slots.add({'time_minutes': minutes, 'state': state});
      }
      days[key] = slots;
    }

    return {
      'ok': true,
      'service': service.isEmpty ? 'General appointment' : service,
      'timezone': 'America/New_York',
      'today': _dateKey(today),
      'window_days': 15,
      'pending_hold_hours': 48,
      'work_start_minutes': 600,
      'work_end_minutes': 1020,
      'slot_minutes': 30,
      'days': days,
    };
  }

  Future<Map<String, dynamic>> _chatbotConfigPayload() async {
    final full = await _loadObject(MockApiAssets.chatbotReplies);
    return {
      'suggestions': full['suggestions'] ?? const <String>[],
      'disclaimer': full['disclaimer'] ?? '',
      'emptyPrompt': full['emptyPrompt'] ?? '',
    };
  }

  Future<Map<String, dynamic>> _bookOnlineCatalogPayload() async {
    return _loadObject(MockApiAssets.bookOnline);
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

  Future<Map<String, dynamic>> _conditionsListPayload() async {
    final root = await _loadObject(MockApiAssets.conditions);
    final list = root['conditions'] as List<dynamic>? ?? const [];
    return {
      'title': (root['title'] as String?)?.trim().isNotEmpty == true
          ? root['title']
          : 'conditions we treat',
      'content': root['content'] ?? '',
      'conditions': list.whereType<Map>().map((item) {
        final map = item.map((key, value) => MapEntry('$key', value));
        final id = '${map['id'] ?? map['slug'] ?? ''}'.trim();
        return {
          'id': id,
          'title': '${map['title'] ?? map['name'] ?? ''}'.trim(),
          'description': '${map['description'] ?? map['summary'] ?? ''}'.trim(),
          'heroImage': '${map['heroImage'] ?? map['heroImageUrl'] ?? ''}'.trim(),
          'slug': '${map['slug'] ?? id}'.trim(),
        };
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _blogListPayload() async {
    final root = await _loadObject(MockApiAssets.blog);
    final list = root['articles'] as List<dynamic>? ?? const [];
    return {
      'title': (root['title'] as String?)?.trim().isNotEmpty == true
          ? root['title']
          : 'be the change blog',
      'articles': list.whereType<Map>().map((item) {
        final map = item.map((key, value) => MapEntry('$key', value));
        final id = '${map['id'] ?? map['slug'] ?? ''}'.trim();
        final image = '${map['heroImage'] ?? map['imageUrl'] ?? ''}'.trim();
        return {
          'id': id,
          'title': '${map['title'] ?? ''}'.trim(),
          'subtitle': '${map['subtitle'] ?? map['summary'] ?? ''}'.trim(),
          'heroImage': image,
          'imageUrl': image,
          'publishedAt': '${map['publishedAt'] ?? map['date'] ?? ''}'.trim(),
          'slug': '${map['slug'] ?? id}'.trim(),
        };
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _servicesListPayload() async {
    final root = await _loadObject(MockApiAssets.services);
    final list = root['services'] as List<dynamic>? ?? const [];
    return {
      'title': (root['title'] as String?)?.trim().isNotEmpty == true
          ? root['title']
          : 'our services',
      'content': root['content'] ?? '',
      'services': list.whereType<Map>().map((item) {
        final map = item.map((key, value) => MapEntry('$key', value));
        final id = '${map['id'] ?? map['slug'] ?? ''}'.trim();
        return {
          'id': id,
          'title': '${map['title'] ?? map['name'] ?? ''}'.trim(),
          'description': '${map['description'] ?? map['summary'] ?? ''}'.trim(),
          'heroImage': '${map['heroImage'] ?? map['heroImageUrl'] ?? ''}'.trim(),
          'slug': '${map['slug'] ?? id}'.trim(),
        };
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _itemById(
    String assetPath, {
    required String listKey,
    required String id,
    required String notFoundLabel,
    String alternateIdKey = '',
  }) async {
    final root = await _loadObject(assetPath);
    final list = root[listKey] as List<dynamic>? ?? const [];
    for (final entry in list) {
      if (entry is Map<String, dynamic> &&
          (entry['id'] == id ||
              (alternateIdKey.isNotEmpty && entry[alternateIdKey] == id))) {
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
