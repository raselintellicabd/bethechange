import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/mock_api_assets.dart';
import '../../../core/utils/asset_loader.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/chatbot_config.dart';
import 'chatbot_repository.dart';

/// Asks the website assistant via `POST /api/v1/chatbot/ask/`.
/// Welcome text, chips and disclaimer are bundled (the web hard-codes them too).
class ChatbotApiRepository implements ChatbotRepository {
  ChatbotApiRepository(this._client, {AssetLoader? loader})
      : _loader = loader ?? AssetLoader();

  final ApiClient _client;
  final AssetLoader _loader;

  @override
  Future<ApiResult<ChatbotReply>> ask({
    required String message,
    List<Map<String, String>> history = const [],
  }) {
    return _client.post(
      ApiPaths.chatbotAsk,
      data: {'message': message, 'history': history},
      extra: const {'skipAuth': true},
      parser: (data) => ChatbotReply.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResult<ChatbotConfig>> getConfig() {
    return _loader.loadJsonObject(
      MockApiAssets.chatbotReplies,
      parser: ChatbotConfig.fromJson,
    );
  }
}
