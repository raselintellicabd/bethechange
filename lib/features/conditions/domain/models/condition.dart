import '../../../../core/domain/models/content_block.dart';
import '../../../../core/domain/models/labeled_list_item.dart';
import '../../../../core/domain/models/recommended_book.dart';

/// A treatable condition shown under the Conditions tab.
class Condition {
  const Condition({
    required this.id,
    required this.name,
    required this.summary,
    required this.articleBody,
    this.heroImageUrl,
    this.symptoms = const [],
    this.contributingFactors = const [],
    this.integrativeApproach,
    this.benefits = const [],
    this.treatmentMethods = const [],
    this.recommendedBooks = const [],
  });

  final String id;
  final String name;
  final String summary;
  final String articleBody;
  final String? heroImageUrl;

  /// Symptom items (plan: SymptomItem) — shared [LabeledListItem] shape.
  final List<LabeledListItem> symptoms;

  final List<LabeledListItem> contributingFactors;
  final ContentBlock? integrativeApproach;
  final List<LabeledListItem> benefits;

  /// Treatment methods (plan: TreatmentMethod) — shared [LabeledListItem] shape.
  final List<LabeledListItem> treatmentMethods;
  final List<RecommendedBook> recommendedBooks;

  String get integrativeApproachTitle =>
      integrativeApproach?.title ?? 'Our Integrative Approach to $name';

  String get benefitsTitle => 'Benefits of Integrative Medicine for $name';

  String get treatmentTitle => 'Ways We Can Treat $name';

  factory Condition.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final name = (json['name'] as String?)?.trim() ?? '';
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Condition id and name are required.');
    }

    return Condition(
      id: id,
      name: name,
      summary: json['summary'] as String? ?? '',
      articleBody: json['articleBody'] as String? ?? '',
      heroImageUrl: json['heroImageUrl'] as String?,
      symptoms: _parseItems(json['symptoms']),
      contributingFactors: _parseItems(json['contributingFactors']),
      integrativeApproach: json['integrativeApproach'] == null
          ? null
          : ContentBlock.fromJson(
              json['integrativeApproach'] as Map<String, dynamic>,
            ),
      benefits: _parseItems(json['benefits']),
      treatmentMethods: _parseItems(json['treatmentMethods']),
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
