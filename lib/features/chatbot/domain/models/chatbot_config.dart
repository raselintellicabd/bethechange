class ChatbotSuggestion {
  const ChatbotSuggestion({required this.label, required this.message});

  final String label;

  /// Question sent to the assistant when the chip is tapped.
  final String message;

  factory ChatbotSuggestion.fromJson(Object? json) {
    if (json is Map) {
      final label = '${json['label'] ?? ''}'.trim();
      final message = '${json['message'] ?? ''}'.trim();
      return ChatbotSuggestion(
        label: label,
        message: message.isEmpty ? label : message,
      );
    }
    final text = '${json ?? ''}'.trim();
    return ChatbotSuggestion(label: text, message: text);
  }
}

class ChatbotConfig {
  const ChatbotConfig({
    required this.suggestions,
    required this.disclaimer,
    required this.welcome,
  });

  final List<ChatbotSuggestion> suggestions;
  final String disclaimer;
  final String welcome;

  factory ChatbotConfig.fromJson(Map<String, dynamic> json) {
    final suggestions = (json['suggestions'] as List<dynamic>? ?? const [])
        .map(ChatbotSuggestion.fromJson)
        .where((e) => e.label.isNotEmpty)
        .toList();

    return ChatbotConfig(
      suggestions: suggestions,
      disclaimer: (json['disclaimer'] as String?)?.trim() ?? '',
      welcome: (json['welcome'] as String?)?.trim() ?? '',
    );
  }
}
