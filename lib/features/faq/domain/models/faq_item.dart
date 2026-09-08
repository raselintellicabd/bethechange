/// A single FAQ question/answer pair.
class FaqItem {
  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
  });

  final String id;
  final String question;
  final String answer;

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final question = (json['question'] as String?)?.trim() ?? '';
    if (id.isEmpty || question.isEmpty) {
      throw const FormatException('FaqItem id and question are required.');
    }

    return FaqItem(
      id: id,
      question: question,
      answer: json['answer'] as String? ?? '',
    );
  }
}
