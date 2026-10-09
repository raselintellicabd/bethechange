import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the open chat's token so the conversation survives an app restart.
class LiveChatTokenStore {
  LiveChatTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'btc_live_chat_token';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _key);

  Future<void> save(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);
}

/// In-memory store for tests and mock mode.
class MemoryLiveChatTokenStore extends LiveChatTokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> save(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
