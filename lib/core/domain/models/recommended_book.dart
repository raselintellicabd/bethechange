/// Recommended reading item shown on Conditions/Services detail screens.
class RecommendedBook {
  const RecommendedBook({
    required this.title,
    required this.author,
    this.coverUrl,
    this.purchaseUrl,
  });

  final String title;
  final String author;
  final String? coverUrl;
  final String? purchaseUrl;

  factory RecommendedBook.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String?)?.trim() ?? '';
    final author = (json['author'] as String?)?.trim() ?? '';
    if (title.isEmpty) {
      throw const FormatException('RecommendedBook title is required.');
    }
    if (author.isEmpty) {
      throw const FormatException('RecommendedBook author is required.');
    }

    return RecommendedBook(
      title: title,
      author: author,
      coverUrl: json['coverUrl'] as String?,
      purchaseUrl: json['purchaseUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        if (coverUrl != null) 'coverUrl': coverUrl,
        if (purchaseUrl != null) 'purchaseUrl': purchaseUrl,
      };
}
