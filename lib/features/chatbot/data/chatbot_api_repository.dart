import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/chatbot_config.dart';
import 'chatbot_repository.dart';

/// Chatbot networking via `POST /chatbot/message` and `GET /chatbot/config`.
class ChatbotApiRepository implements ChatbotRepository {
  ChatbotApiRepository(this._client);

  final ApiClient _client;

  @override
  Future<ApiResult<ChatbotReply>> sendMessage({
    required String message,
    String? conversationId,
  }) {
    return _client.post(
      ApiPaths.chatbotMessage,
      data: {
        'message': message,
        'conversationId': ?conversationId,
      },
      parser: (data) => ChatbotReply.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResult<ChatbotConfig>> getConfig() {
    return _client.get(
      ApiPaths.chatbotConfig,
      parser: (data) => ChatbotConfig.fromJson(data as Map<String, dynamic>),
    );
  }
}
