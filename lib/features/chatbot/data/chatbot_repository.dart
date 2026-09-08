import '../../../core/network/api_result.dart';
import '../domain/models/chat_message.dart';

/// Chatbot networking contract. See `chatbot_api_contract.dart`.
abstract class ChatbotRepository {
  Future<ApiResult<ChatbotReply>> sendMessage({
    required String message,
    String? conversationId,
  });
}
