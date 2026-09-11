import '../../../../core/domain/models/content_block.dart';
import '../../../../core/domain/models/labeled_list_item.dart';
import '../../../../core/domain/models/recommended_book.dart';
import '../../../about/domain/models/review.dart';

/// A treatable condition shown under the Conditions tab.
class Condition {
  const Condition({
    required this.id,
    required this.name,
    required this.summary,
    required this.articleBody,
    this.slug = '',
    this.heroImageUrl,
    this.quote,
    this.ctaLabel,
    this.symptoms = const [],
    this.contributingFactors = const [],
    this.integrativeApproach,
    this.benefits = const [],
    this.treatmentMethods = const [],
    this.recommendedBooks = const [],
    this.reviews = const [],
    this.symptomsTitle,
    this.factorsTitle,
    this.benefitsTitleOverride,
    this.treatmentTitleOverride,
    this.booksTitle,
    this.booksSubtitle,
    this.overviewImageUrl,
    this.symptomsImageUrl,
    this.factorsImageUrl,
    this.gettingStarted = const [],
  });

  final String id;

  /// Detail path segment. Same as [id] when the API does not send a slug.
  final String slug;
  final String name;
  final String summary;
  final String articleBody;
  final String? heroImageUrl;
  final String? quote;
  final String? ctaLabel;

  /// Symptom items (plan: SymptomItem) — shared [LabeledListItem] shape.
  final List<LabeledListItem> symptoms;

  final List<LabeledListItem> contributingFactors;
  final ContentBlock? integrativeApproach;
  final List<LabeledListItem> benefits;

  /// Treatment methods (plan: TreatmentMethod) — shared [LabeledListItem] shape.
  final List<LabeledListItem> treatmentMethods;
  final List<RecommendedBook> recommendedBooks;
  final List<Review> reviews;
  final String? symptomsTitle;
  final String? factorsTitle;
  final String? benefitsTitleOverride;
  final String? treatmentTitleOverride;
  final String? booksTitle;
  final String? booksSubtitle;
  final String? overviewImageUrl;
  final String? symptomsImageUrl;
  final String? factorsImageUrl;
  final List<LabeledListItem> gettingStarted;

  String get routeId {
    final value = slug.trim();
    return value.isEmpty ? id : value;
  }

  String get integrativeApproachTitle =>
      integrativeApproach?.title ?? 'Our Integrative Approach to $name';

  String get symptomsSectionTitle => symptomsTitle ?? 'Common Symptoms';

  String get factorsSectionTitle => factorsTitle ?? 'Factors That Contribute';

  String get benefitsTitle =>
      benefitsTitleOverride ?? 'Benefits of Integrative Medicine for $name';

  String get treatmentTitle =>
      treatmentTitleOverride ?? 'Ways We Can Treat $name';

  factory Condition.fromJson(Map<String, dynamic> json) {
    final id = _text(json, const ['id', 'slug']);
    final name = _text(json, const ['name', 'title']);
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Condition id and name are required.');
    }

    final sections = _maps(json['sections']);

    return Condition(
      id: id,
      slug: _text(json, const ['slug', 'id']),
      name: name,
      summary: _text(json, const ['summary', 'description', 'content']),
      articleBody: _text(json, const ['articleBody']),
      heroImageUrl: _url(json, const ['heroImageUrl', 'heroImage', 'img-url']),
      quote: _nullableText(json, const ['quote']),
      ctaLabel: _nullableText(json, const ['cta-label', 'ctaLabel']),
      symptoms: _parseItems(json['symptoms']),
      contributingFactors: _parseItems(json['contributingFactors']),
      integrativeApproach: _parseApproach(json['integrativeApproach']),
      benefits: _parseItems(json['benefits']),
      treatmentMethods: _withSectionImages(
        _parseItems(json['treatmentMethods']),
        _sectionItems(sections, 'treat_dark'),
      ),
      recommendedBooks: _booksWithCovers(
        _maps(json['recommendedBooks']),
        _sectionItems(sections, 'books'),
      ),
      reviews: _maps(json['reviews']).map(Review.fromJson).toList(),
      symptomsTitle: _sectionTitle(sections, 'symptoms'),
      factorsTitle: _sectionTitle(sections, 'factors'),
      treatmentTitleOverride: _sectionTitle(sections, 'treat_dark'),
      booksTitle: _sectionTitle(sections, 'books'),
      booksSubtitle: _sectionContent(sections, 'books'),
      overviewImageUrl: _sectionImage(sections, 'now_control'),
      symptomsImageUrl: _sectionImage(sections, 'symptoms'),
      factorsImageUrl: _sectionImage(sections, 'factors'),
      gettingStarted: _sectionCards(sections, 'getting_started'),
    );
  }

  static List<LabeledListItem> _parseItems(Object? raw) {
    return _maps(raw).map(LabeledListItem.fromJson).toList();
  }

  static ContentBlock? _parseApproach(Object? raw) {
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

  static String? _sectionImage(
    List<Map<String, dynamic>> sections,
    String layout,
  ) {
    final section = _section(sections, layout);
    if (section == null) return null;
    return _url(section, const ['img-url', 'imageUrl', 'heroImage']);
  }

  static List<Map<String, dynamic>> _sectionItems(
    List<Map<String, dynamic>> sections,
    String layout,
  ) {
    final section = _section(sections, layout);
    if (section == null) return const [];
    return _maps(section['items']);
  }

  static List<LabeledListItem> _sectionCards(
    List<Map<String, dynamic>> sections,
    String layout,
  ) {
    return _sectionItems(sections, layout).map((item) {
      return LabeledListItem(
        label: _text(item, const ['title', 'label']),
        description: _nullableText(item, const ['content', 'description']),
        iconUrl: _url(item, const ['img-url', 'imageUrl', 'iconUrl']),
      );
    }).where((item) => item.label.isNotEmpty).toList();
  }

  static List<LabeledListItem> _withSectionImages(
    List<LabeledListItem> items,
    List<Map<String, dynamic>> sectionItems,
  ) {
    if (sectionItems.isEmpty) return items;
    return [
      for (var i = 0; i < items.length; i++)
        LabeledListItem(
          label: items[i].label,
          description: items[i].description,
          iconUrl: items[i].iconUrl ??
              (i < sectionItems.length
                  ? _url(sectionItems[i], const ['img-url', 'imageUrl', 'iconUrl'])
                  : null),
        ),
    ];
  }

  static List<RecommendedBook> _booksWithCovers(
    List<Map<String, dynamic>> books,
    List<Map<String, dynamic>> sectionItems,
  ) {
    return [
      for (var i = 0; i < books.length; i++)
        RecommendedBook.fromJson({
          ...books[i],
          if ((books[i]['coverUrl'] == null ||
                  '${books[i]['coverUrl']}'.trim().isEmpty) &&
              i < sectionItems.length)
            'coverUrl': _url(
              sectionItems[i],
              const ['img-url', 'coverUrl', 'imageUrl'],
            ),
        }),
    ];
  }

  static String? _sectionTitle(
    List<Map<String, dynamic>> sections,
    String layout,
  ) {
    final section = _section(sections, layout);
    if (section == null) return null;
    return _nullableText(section, const ['title']);
  }

  static String? _sectionContent(
    List<Map<String, dynamic>> sections,
    String layout,
  ) {
    final section = _section(sections, layout);
    if (section == null) return null;
    return _nullableText(section, const ['content']);
  }

  static Map<String, dynamic>? _section(
    List<Map<String, dynamic>> sections,
    String layout,
  ) {
    for (final section in sections) {
      if ('${section['layout']}'.trim() == layout) return section;
    }
    return null;
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
