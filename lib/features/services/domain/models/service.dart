import '../../../../core/domain/models/content_block.dart';
import '../../../../core/domain/models/labeled_list_item.dart';
import '../../../../core/domain/models/recommended_book.dart';

/// A clinic service/therapy shown under the Services tab.
class Service {
  const Service({
    required this.id,
    required this.name,
    required this.summary,
    required this.articleBody,
    this.heroImageUrl,
    this.howItWorks,
    this.benefits = const [],
    this.addressedConcerns = const [],
    this.whatToExpect,
    this.recommendedBooks = const [],
  });

  final String id;
  final String name;
  final String summary;
  final String articleBody;
  final String? heroImageUrl;
  final ContentBlock? howItWorks;
  final List<LabeledListItem> benefits;
  final List<LabeledListItem> addressedConcerns;
  final ContentBlock? whatToExpect;
  final List<RecommendedBook> recommendedBooks;

  String get howItWorksTitle => howItWorks?.title ?? 'How $name Works';

  String get benefitsTitle => 'Benefits of $name';

  String get addressedConcernsTitle => 'What $name Can Address';

  String get whatToExpectTitle =>
      whatToExpect?.title ?? 'What To Expect';

  factory Service.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final name = (json['name'] as String?)?.trim() ?? '';
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Service id and name are required.');
    }

    return Service(
      id: id,
      name: name,
      summary: json['summary'] as String? ?? '',
      articleBody: json['articleBody'] as String? ?? '',
      heroImageUrl: json['heroImageUrl'] as String?,
      howItWorks: json['howItWorks'] == null
          ? null
          : ContentBlock.fromJson(json['howItWorks'] as Map<String, dynamic>),
      benefits: _parseItems(json['benefits']),
      addressedConcerns: _parseItems(json['addressedConcerns']),
      whatToExpect: json['whatToExpect'] == null
          ? null
          : ContentBlock.fromJson(json['whatToExpect'] as Map<String, dynamic>),
      recommendedBooks: (json['recommendedBooks'] as List<dynamic>? ?? const [])
          .map(
            (item) => RecommendedBook.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  static List<LabeledListItem> _parseItems(Object? raw) {
    return (raw as List<dynamic>? ?? const [])
        .map((item) => LabeledListItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
