import '../../../about/domain/models/review.dart';

class MembershipPlanSection {
  const MembershipPlanSection({
    required this.heading,
    required this.items,
  });

  final String heading;
  final List<String> items;

  factory MembershipPlanSection.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map((item) => '$item'.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return MembershipPlanSection(
      heading: (json['heading'] as String?)?.trim() ?? '',
      items: items,
    );
  }
}

class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.sections,
    this.heroImageUrl,
    this.buttonLabel,
    this.buttonUrl,
    this.priceLabel,
    this.tier = 0,
    this.priceCents = 0,
    this.durationDays = 0,
  });

  final int id;
  final String title;
  final String description;
  final String? heroImageUrl;
  final List<MembershipPlanSection> sections;
  final String? buttonLabel;
  final String? buttonUrl;
  final String? priceLabel;
  final int tier;
  final int priceCents;
  final int durationDays;

  bool get isJoinable => tier >= 1 && tier <= 3;

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
    final priceLabel = (json['price_label'] as String?)?.trim() ??
        (json['priceLabel'] as String?)?.trim();

    final sections = (json['sections'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => MembershipPlanSection.fromJson(
            item.map((key, value) => MapEntry('$key', value)),
          ),
        )
        .where((section) => section.heading.isNotEmpty || section.items.isNotEmpty)
        .toList();

    return MembershipPlan(
      id: id,
      title: title,
      description: (json['description'] as String?)?.trim() ?? '',
      heroImageUrl: hero == null || hero.isEmpty ? null : hero,
      sections: sections,
      buttonLabel:
          buttonLabel == null || buttonLabel.isEmpty ? 'Join Now' : buttonLabel,
      buttonUrl: buttonUrl == null || buttonUrl.isEmpty ? null : buttonUrl,
      priceLabel: priceLabel == null || priceLabel.isEmpty ? null : priceLabel,
      tier: (json['tier'] as num?)?.toInt() ?? 0,
      priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 0,
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
