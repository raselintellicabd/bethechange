import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/live_chat.dart';
import 'live_chat_token_store.dart';

/// Live chat with the clinic team (`/api/v1/livechat/*`).
///
/// The token from `start` identifies the visitor's chat on every later call
/// via the `X-Chat-Token` header; without it the server reports `status: none`.
class LiveChatRepository {
  LiveChatRepository(this._client, this._tokens);

  static const tokenHeader = 'X-Chat-Token';
  static const _noAuth = {'skipAuth': true};

  final ApiClient _client;
  final LiveChatTokenStore _tokens;

  Future<bool> hasToken() async => ((await _tokens.read()) ?? '').isNotEmpty;

  Future<void> forget() => _tokens.clear();

  Future<ApiResult<LiveChatSnapshot>> start({
    required String name,
    required String email,
    String message = '',
  }) async {
    final result = await _client.post(
      ApiPaths.liveChatStart,
      data: {'name': name, 'email': email, 'message': message},
      extra: _noAuth,
      headers: await _headers(),
      parser: _parse,
    );
    if (result case ApiSuccess(:final data) when data.token != null) {
      await _tokens.save(data.token!);
    }
    return result;
  }

  Future<ApiResult<LiveChatSnapshot>> state({int since = 0}) async {
    return _client.get(
      ApiPaths.liveChatState,
      queryParameters: {'since': since},
      headers: await _headers(),
      parser: _parse,
    );
  }

  Future<ApiResult<LiveChatSnapshot>> send(String body, {int since = 0}) async {
    return _client.post(
      ApiPaths.liveChatSend,
      data: {'body': body, 'since': since},
      extra: _noAuth,
      headers: await _headers(),
      parser: _parse,
    );
  }

  Future<ApiResult<LiveChatSnapshot>> end({int since = 0}) async {
    return _client.post(
      ApiPaths.liveChatEnd,
      data: {'since': since},
      extra: _noAuth,
      headers: await _headers(),
      parser: _parse,
    );
  }

  Future<Map<String, dynamic>> _headers() async {
    final token = await _tokens.read();
    return {
      if (token != null && token.isNotEmpty) tokenHeader: token,
    };
  }

  static LiveChatSnapshot _parse(dynamic data) =>
      LiveChatSnapshot.fromJson(Map<String, dynamic>.from(data as Map));
}
