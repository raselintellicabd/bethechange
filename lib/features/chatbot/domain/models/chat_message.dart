enum ChatMessageRole { user, bot }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.links = const [],
  });

  final String id;
  final ChatMessageRole role;
  final String text;
  final DateTime createdAt;
  final List<ChatbotLink> links;
}

/// A website page the assistant used for its answer (url is site-relative).
class ChatbotLink {
  const ChatbotLink({required this.title, required this.url, this.kind = ''});

  final String title;
  final String url;

  /// Page type from the site index, e.g. `Service`, `Condition`, `Blog`,
  /// `Booking`. Needed because service, condition and blog URLs look alike.
  final String kind;

  factory ChatbotLink.fromJson(Map<String, dynamic> json) {
    return ChatbotLink(
      title: '${json['title'] ?? ''}'.trim(),
      url: '${json['url'] ?? ''}'.trim(),
      kind: '${json['kind'] ?? ''}'.trim(),
    );
  }
}

class ChatbotReply {
  const ChatbotReply({
    required this.reply,
    this.links = const [],
    this.handoff = false,
  });

  final String reply;
  final List<ChatbotLink> links;

  /// True when the visitor asked for a person; the app opens live chat.
  final bool handoff;

  factory ChatbotReply.fromJson(Map<String, dynamic> json) {
    final reply = (json['reply'] as String?)?.trim() ?? '';
    if (reply.isEmpty) {
      throw const FormatException('ChatbotReply requires reply.');
    }
    final links = (json['links'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => ChatbotLink.fromJson(Map<String, dynamic>.from(e)))
        .where((l) => l.title.isNotEmpty && l.url.isNotEmpty)
        .toList();
    return ChatbotReply(
      reply: reply,
      links: links,
      handoff: json['handoff'] == true,
    );
  }
}
