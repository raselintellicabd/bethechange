import '../../../core/network/api_result.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/chatbot_config.dart';

/// Chatbot networking contract. See `chatbot_api_contract.dart`.
abstract class ChatbotRepository {
  /// [history] is the recent conversation as `{role, content}` maps
  /// (`role` is `user` or `assistant`), oldest first.
  Future<ApiResult<ChatbotReply>> ask({
    required String message,
    List<Map<String, String>> history = const [],
  });

  Future<ApiResult<ChatbotConfig>> getConfig();
}
