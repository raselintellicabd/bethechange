import '../../../../core/domain/models/content_block.dart';
import '../../../../core/domain/models/labeled_list_item.dart';
import '../../../../core/domain/models/recommended_book.dart';

class ServiceSectionItem {
  const ServiceSectionItem({
    this.title = '',
    this.content = '',
    this.imageUrl,
    this.linkUrl,
  });

  final String title;
  final String content;
  final String? imageUrl;
  final String? linkUrl;

  List<String> get lines {
    return content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Path like `/ion-foot-detox/` becomes `ion-foot-detox`.
  String? get linkSlug {
    final raw = linkUrl?.trim() ?? '';
    if (raw.isEmpty) return null;
    final path = Uri.tryParse(raw)?.path ?? raw;
    final slug = path.split('/').where((part) => part.isNotEmpty).join('/');
    return slug.isEmpty ? null : slug;
  }
}

class ServiceSection {
  const ServiceSection({
    required this.type,
    this.title = '',
    this.content = '',
    this.imageUrl,
    this.items = const [],
  });

  final String type;
  final String title;
  final String content;
  final String? imageUrl;
  final List<ServiceSectionItem> items;

  bool get hasImages =>
      (imageUrl != null && imageUrl!.isNotEmpty) ||
      items.any((item) => item.imageUrl != null && item.imageUrl!.isNotEmpty);
}

/// A clinic service/therapy shown under the Services tab.
class Service {
  const Service({
    required this.id,
    required this.name,
    required this.summary,
    required this.articleBody,
    this.slug = '',
    this.heroImageUrl,
    this.quote,
    this.ctaLabel,
    this.howItWorks,
    this.benefits = const [],
    this.addressedConcerns = const [],
    this.whatToExpect,
    this.recommendedBooks = const [],
    this.sections = const [],
  });

  final String id;
  final String slug;
  final String name;
  final String summary;
  final String articleBody;
  final String? heroImageUrl;
  final String? quote;
  final String? ctaLabel;
  final ContentBlock? howItWorks;
  final List<LabeledListItem> benefits;
  final List<LabeledListItem> addressedConcerns;
  final ContentBlock? whatToExpect;
  final List<RecommendedBook> recommendedBooks;
  final List<ServiceSection> sections;

  String get routeId {
    final value = slug.trim();
    return value.isEmpty ? id : value;
  }

  String get howItWorksTitle => howItWorks?.title ?? 'How $name Works';

  String get benefitsTitle => 'Benefits of $name';

  String get addressedConcernsTitle => 'What $name Can Address';

  String get whatToExpectTitle => whatToExpect?.title ?? 'What To Expect';

  factory Service.fromJson(Map<String, dynamic> json) {
    final id = _text(json, const ['id', 'slug']);
    final name = _text(json, const ['title', 'name']);
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Service id and name are required.');
    }

    return Service(
      id: id,
      slug: _text(json, const ['slug', 'id']),
      name: name,
      summary: _text(json, const ['summary', 'description', 'content']),
      articleBody: _text(json, const ['articleBody']),
      heroImageUrl: _url(json, const ['heroImageUrl', 'heroImage', 'img-url']),
      quote: _nullableText(json, const ['quote']),
      ctaLabel: _nullableText(json, const ['cta-label', 'ctaLabel']),
      howItWorks: _parseBlock(json['howItWorks']),
      benefits: _parseItems(json['benefits']),
      addressedConcerns: _parseItems(json['addressedConcerns']),
      whatToExpect: _parseBlock(json['whatToExpect']),
      recommendedBooks: _maps(json['recommendedBooks'])
          .map(RecommendedBook.fromJson)
          .toList(),
      sections: _maps(json['sections']).map(_section).toList(),
    );
  }

  static ServiceSection _section(Map<String, dynamic> json) {
    return ServiceSection(
      type: _text(json, const ['type']),
      title: _text(json, const ['title']),
      content: _text(json, const ['content']),
      imageUrl: _url(json, const ['img-url', 'imageUrl', 'heroImage']),
      items: _maps(json['items']).map((item) {
        return ServiceSectionItem(
          title: _text(item, const ['title', 'label']),
          content: _text(item, const ['content', 'description']),
          imageUrl: _url(item, const ['img-url', 'imageUrl', 'iconUrl']),
          linkUrl: _nullableText(item, const ['link-url', 'linkUrl']),
        );
      }).toList(),
    );
  }

  static ContentBlock? _parseBlock(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.map((key, value) => MapEntry('$key', value));
    final title = _text(json, const ['title']);
    if (title.isEmpty) return null;
    return ContentBlock(
      title: title,
      body: _nullableText(json, const ['body']),
      imageUrl: _url(json, const ['imageUrl', 'img-url']),
    );
  }

  static List<LabeledListItem> _parseItems(Object? raw) {
    return _maps(raw)
        .map(LabeledListItem.fromJson)
        .where((item) => item.label.trim().isNotEmpty)
        .toList();
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

  static List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) {
      return item.map((key, value) => MapEntry('$key', value));
    }).toList();
  }
}
