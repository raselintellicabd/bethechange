import '../../../about/domain/models/review.dart';
import 'faq_item.dart';

class FaqSection {
  const FaqSection({
    required this.id,
    required this.title,
    required this.items,
  });

  final String id;
  final String title;
  final List<FaqItem> items;

  factory FaqSection.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) {
      throw const FormatException('FaqSection id is required.');
    }
    return FaqSection(
      id: id,
      title: (json['title'] as String?)?.trim() ?? '',
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => FaqItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FaqPolicies {
  const FaqPolicies({
    required this.id,
    required this.title,
    required this.content,
  });

  final String id;
  final String title;
  final String content;

  factory FaqPolicies.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final title = (json['title'] as String?)?.trim() ?? '';
    if (id.isEmpty || title.isEmpty) {
      throw const FormatException('FaqPolicies id and title are required.');
    }
    return FaqPolicies(
      id: id,
      title: title,
      content: json['content'] as String? ?? '',
    );
  }
}

class FaqCatalog {
  const FaqCatalog({
    required this.items,
    this.title = 'FAQ',
    this.sections = const [],
    this.policies,
    this.buttonLabel,
    this.buttonUrl,
    this.reviews = const [],
  });

  final String title;
  final List<FaqItem> items;
  final List<FaqSection> sections;
  final FaqPolicies? policies;
  final String? buttonLabel;
  final String? buttonUrl;
  final List<Review> reviews;

  /// Section groups to render. Falls back to the flat item list.
  ///
  /// The office-policies entry is rendered from [policies], not repeated here.
  List<FaqSection> get displaySections {
    final policiesId = policies?.id;
    if (sections.isNotEmpty) {
      return [
        for (final section in sections)
          FaqSection(
            id: section.id,
            title: section.title,
            items: section.items
                .where((item) => item.id != policiesId)
                .toList(),
          ),
      ];
    }

    return [
      FaqSection(
        id: 'all',
        title: '',
        items: items.where((item) => item.id != policiesId).toList(),
      ),
    ];
  }

  /// Flat items that are not already inside [sections] or [policies].
  List<FaqItem> get ungroupedItems {
    if (sections.isEmpty) return const [];
    final grouped = <String>{
      for (final section in sections)
        for (final item in section.items) item.id,
      if (policies != null) policies!.id,
    };
    return items.where((item) => !grouped.contains(item.id)).toList();
  }

  factory FaqCatalog.fromJson(Map<String, dynamic> json) {
    final policiesJson = json['policies'];
    final buttonLabel = _text(json, const ['button-label', 'buttonLabel']);
    final buttonUrl = _text(json, const ['button-url', 'buttonUrl']);

    return FaqCatalog(
      title: _text(json, const ['title']).isEmpty
          ? 'FAQ'
          : _text(json, const ['title']),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => FaqItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .map((item) => FaqSection.fromJson(item as Map<String, dynamic>))
          .toList(),
      policies: policiesJson is Map<String, dynamic>
          ? FaqPolicies.fromJson(policiesJson)
          : null,
      buttonLabel: buttonLabel.isEmpty ? null : buttonLabel,
      buttonUrl: buttonUrl.isEmpty ? null : buttonUrl,
      reviews: (json['reviews'] as List<dynamic>? ?? const [])
          .map((item) => Review.fromJson(item as Map<String, dynamic>))
          .where((review) => review.reviewerName.isNotEmpty)
          .toList(),
    );
  }

  static String _text(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}
