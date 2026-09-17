import '../../../about/domain/models/review.dart';

class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.benefits,
    this.heroImageUrl,
    this.buttonLabel,
    this.buttonUrl,
  });

  final int id;
  final String title;
  final String description;
  final String? heroImageUrl;
  final List<String> benefits;
  final String? buttonLabel;
  final String? buttonUrl;

  /// Price line extracted from benefits or description.
  String? get priceLabel {
    for (final benefit in benefits) {
      final trimmed = benefit.trim();
      if (trimmed.toLowerCase().startsWith('membership price')) {
        return trimmed;
      }
    }
    for (final line in description.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('membership price')) {
        return trimmed;
      }
    }
    return null;
  }

  /// Benefits suitable for checklist display (labels/price omitted).
  List<String> get displayBenefits {
    return [
      for (final benefit in benefits)
        if (_isDisplayBenefit(benefit)) benefit.trim(),
    ];
  }

  static bool _isDisplayBenefit(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return false;
    if (value == 'this package includes:') return false;
    if (value == 'this package includes') return false;
    if (value.startsWith('membership price')) return false;
    return true;
  }

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int
        ? idRaw
        : int.tryParse('${idRaw ?? ''}'.trim()) ?? 0;
    final title = (json['title'] as String?)?.trim() ?? '';
    if (id <= 0 || title.isEmpty) {
      throw const FormatException('MembershipPlan id and title are required.');
    }

    final hero = (json['heroImage'] as String?)?.trim() ??
        (json['heroImageUrl'] as String?)?.trim();
    final buttonLabel = (json['button-label'] as String?)?.trim() ??
        (json['buttonLabel'] as String?)?.trim();
    final buttonUrl = (json['button-url'] as String?)?.trim() ??
        (json['buttonUrl'] as String?)?.trim();

    final benefits = (json['benefits'] as List<dynamic>? ?? const [])
        .map((item) => '$item'.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return MembershipPlan(
      id: id,
      title: title,
      description: (json['description'] as String?)?.trim() ?? '',
      heroImageUrl: hero == null || hero.isEmpty ? null : hero,
      benefits: benefits,
      buttonLabel:
          buttonLabel == null || buttonLabel.isEmpty ? 'Join Now' : buttonLabel,
      buttonUrl: buttonUrl == null || buttonUrl.isEmpty ? null : buttonUrl,
    );
  }
}

class MembershipCatalog {
  const MembershipCatalog({
    required this.title,
    required this.content,
    required this.plans,
    this.reviews = const [],
  });

  final String title;
  final String content;
  final List<MembershipPlan> plans;
  final List<Review> reviews;

  factory MembershipCatalog.fromJson(Map<String, dynamic> json) {
    final plans = (json['plans'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => MembershipPlan.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ))
        .toList();

    final reviews = (json['reviews'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Review.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ))
        .toList();

    return MembershipCatalog(
      title: (json['title'] as String?)?.trim() ?? 'Membership Packages',
      content: (json['content'] as String?)?.trim() ?? '',
      plans: plans,
      reviews: reviews,
    );
  }
}
