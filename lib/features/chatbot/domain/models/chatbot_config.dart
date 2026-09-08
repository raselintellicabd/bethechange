class ChatbotConfig {
  const ChatbotConfig({
    required this.suggestions,
    required this.disclaimer,
    required this.emptyPrompt,
  });

  final List<String> suggestions;
  final String disclaimer;
  final String emptyPrompt;

  factory ChatbotConfig.fromJson(Map<String, dynamic> json) {
    final suggestions = (json['suggestions'] as List<dynamic>? ?? const [])
        .map((e) => '$e'.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return ChatbotConfig(
      suggestions: suggestions,
      disclaimer: (json['disclaimer'] as String?)?.trim() ?? '',
      emptyPrompt: (json['emptyPrompt'] as String?)?.trim() ?? '',
    );
  }
}
