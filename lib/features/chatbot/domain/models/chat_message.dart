enum ChatMessageRole { user, bot }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final ChatMessageRole role;
  final String text;
  final DateTime createdAt;
}

class ChatbotReply {
  const ChatbotReply({
    required this.reply,
    required this.conversationId,
  });

  final String reply;
  final String conversationId;

  factory ChatbotReply.fromJson(Map<String, dynamic> json) {
    final reply = (json['reply'] as String?)?.trim() ?? '';
    final conversationId =
        (json['conversationId'] as String?)?.trim() ?? '';
    if (reply.isEmpty || conversationId.isEmpty) {
      throw const FormatException(
        'ChatbotReply requires reply and conversationId.',
      );
    }
    return ChatbotReply(reply: reply, conversationId: conversationId);
  }

  Map<String, dynamic> toJson() => {
        'reply': reply,
        'conversationId': conversationId,
      };
}
