import '../../../core/network/api_result.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/chatbot_config.dart';

/// Chatbot networking contract. See `chatbot_api_contract.dart`.
abstract class ChatbotRepository {
  Future<ApiResult<ChatbotReply>> sendMessage({
    required String message,
    String? conversationId,
  });

  Future<ApiResult<ChatbotConfig>> getConfig();
}
