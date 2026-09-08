/// A blog article shown under the Blog tab.
class BlogArticle {
  const BlogArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
    this.imageUrl,
    this.author,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String body;
  final String? imageUrl;
  final String? author;

  /// ISO-8601 date string when available (e.g. `2024-08-22`).
  final String? publishedAt;

  factory BlogArticle.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final title = (json['title'] as String?)?.trim() ?? '';
    if (id.isEmpty || title.isEmpty) {
      throw const FormatException('BlogArticle id and title are required.');
    }

    return BlogArticle(
      id: id,
      title: title,
      subtitle: json['subtitle'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      author: json['author'] as String?,
      publishedAt: json['publishedAt'] as String? ?? json['date'] as String?,
    );
  }
}
