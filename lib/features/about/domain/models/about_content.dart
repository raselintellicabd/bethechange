/// Catalog payload from `GET /api/v1/about/`.
class AboutContent {
  const AboutContent({
    required this.title,
    required this.pages,
  });

  final String title;
  final List<AboutPageSummary> pages;

  AboutPageSummary? pageBySlug(String slug) {
    for (final page in pages) {
      if (page.slug == slug) return page;
    }
    return null;
  }

  factory AboutContent.fromJson(Map<String, dynamic> json) {
    return AboutContent(
      title: (json['title'] as String?)?.trim() ?? 'About',
      pages: (json['pages'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AboutPageSummary.fromJson(item.map((k, v) => MapEntry('$k', v))),
          )
          .toList(),
    );
  }
}

class AboutPageSummary {
  const AboutPageSummary({
    required this.slug,
    required this.title,
    required this.path,
    required this.kind,
    this.imageUrl,
    this.summary,
  });

  final String slug;
  final String title;
  final String path;
  final String kind;
  final String? imageUrl;
  final String? summary;

  factory AboutPageSummary.fromJson(Map<String, dynamic> json) {
    return AboutPageSummary(
      slug: (json['slug'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      path: (json['path'] as String?)?.trim() ?? '',
      kind: (json['kind'] as String?)?.trim() ?? '',
      imageUrl: _nonEmpty(json['imageUrl'] as String?),
      summary: _nonEmpty(json['summary'] as String?),
    );
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
