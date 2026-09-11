/// A single FAQ question/answer pair.
class FaqItem {
  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    this.section,
  });

  final String id;
  final String question;
  final String answer;

  /// Section id from the API (`appointments`, `therapies`, …).
  final String? section;

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final question = (json['question'] as String?)?.trim() ?? '';
    if (id.isEmpty || question.isEmpty) {
      throw const FormatException('FaqItem id and question are required.');
    }

    final section = (json['section'] as String?)?.trim();
    return FaqItem(
      id: id,
      question: question,
      answer: json['answer'] as String? ?? '',
      section: section == null || section.isEmpty ? null : section,
    );
  }
}
