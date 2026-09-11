import 'package:intl/intl.dart';

/// A blog article shown under the Blog tab.
class BlogArticle {
  const BlogArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
    this.contentHtml,
    this.slug = '',
    this.imageUrl,
    this.author,
    this.publishedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final String body;

  /// Detail HTML from the API (`content_html`). Preferred over [body].
  final String? contentHtml;
  final String? imageUrl;
  final String? author;

  /// ISO-8601 date string when available (e.g. `2024-08-22`).
  final String? publishedAt;

  String get routeId {
    final value = slug.trim();
    return value.isEmpty ? id : value;
  }

  String? get publishedLabel {
    final raw = publishedAt?.trim();
    if (raw == null || raw.isEmpty) return null;
    final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
    if (dateOnly != null) {
      final parsed = DateTime(
        int.parse(dateOnly.group(1)!),
        int.parse(dateOnly.group(2)!),
        int.parse(dateOnly.group(3)!),
      );
      return DateFormat.yMMMMd().format(parsed);
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat.yMMMMd().format(parsed);
  }

  factory BlogArticle.fromJson(Map<String, dynamic> json) {
    final id = _text(json, const ['id', 'slug']);
    final title = _text(json, const ['title']);
    if (id.isEmpty || title.isEmpty) {
      throw const FormatException('BlogArticle id and title are required.');
    }

    return BlogArticle(
      id: id,
      slug: _text(json, const ['slug', 'id']),
      title: title,
      subtitle: _text(json, const ['subtitle', 'summary', 'description']),
      body: _text(json, const ['body', 'articleBody', 'content']),
      contentHtml: _nullableText(json, const ['content_html', 'contentHtml']),
      imageUrl: _url(json, const ['heroImage', 'imageUrl', 'img-url']),
      author: _nullableText(json, const ['author']),
      publishedAt: _nullableText(json, const ['publishedAt', 'date']),
    );
  }

  static String _text(Map<String, dynamic> json, List<String> keys) {
    return _nullableText(json, keys) ?? '';
  }

  static String? _nullableText(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = '$value'.trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static String? _url(Map<String, dynamic> json, List<String> keys) {
    return _nullableText(json, keys);
  }
}
