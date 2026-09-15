import '../../../about/domain/models/doctor_profile.dart';
import '../../../about/domain/models/review.dart';

/// Payload from `GET /api/v1/home/`.
class HomeContent {
  const HomeContent({
    required this.hero,
    required this.approach,
    required this.conditions,
    required this.therapies,
    required this.doctors,
    required this.newsletter,
    required this.reviews,
  });

  final HomeHero hero;
  final HomeApproach approach;
  final HomeConditionsSection conditions;
  final HomeTherapiesSection therapies;
  final HomeDoctorsSection doctors;
  final HomeNewsletter newsletter;
  final List<Review> reviews;

  DoctorProfile? doctorById(String id) {
    for (final doctor in doctors.items) {
      if (doctor.id == id || doctor.routeId == id || doctor.slug == id) {
        return doctor;
      }
    }
    return null;
  }

  factory HomeContent.fromJson(Map<String, dynamic> json) {
    final doctorsBlock = json['doctors'];
    final doctorsMap = doctorsBlock is Map<String, dynamic>
        ? doctorsBlock
        : doctorsBlock is Map
            ? doctorsBlock.map((k, v) => MapEntry('$k', v))
            : <String, dynamic>{};

    return HomeContent(
      hero: HomeHero.fromJson(_asMap(json['hero'])),
      approach: HomeApproach.fromJson(_asMap(json['approach'])),
      conditions: HomeConditionsSection.fromJson(_asMap(json['conditions'])),
      therapies: HomeTherapiesSection.fromJson(_asMap(json['therapies'])),
      doctors: HomeDoctorsSection.fromJson(doctorsMap),
      newsletter: HomeNewsletter.fromJson(_asMap(json['newsletter'])),
      reviews: (json['reviews'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Review.fromJson(item.map((k, v) => MapEntry('$k', v))))
          .toList(),
    );
  }

  static Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry('$k', v));
    return {};
  }
}

class HomeHero {
  const HomeHero({
    required this.text,
    this.imageUrl,
    this.ctaLabel,
    this.ctaUrl,
  });

  final String text;
  final String? imageUrl;
  final String? ctaLabel;
  final String? ctaUrl;

  factory HomeHero.fromJson(Map<String, dynamic> json) {
    return HomeHero(
      text: (json['text'] as String?)?.trim() ?? '',
      imageUrl: _nonEmpty(json['imageUrl'] as String?),
      ctaLabel: _nonEmpty(json['ctaLabel'] as String?),
      ctaUrl: _nonEmpty(json['ctaUrl'] as String?),
    );
  }
}

class HomeApproach {
  const HomeApproach({
    required this.eyebrow,
    required this.headline,
    required this.content,
    this.contentHtml,
    this.imageUrl,
    this.buttonLabel,
    this.buttonUrl,
  });

  final String eyebrow;
  final String headline;
  final String content;
  final String? contentHtml;
  final String? imageUrl;
  final String? buttonLabel;
  final String? buttonUrl;

  factory HomeApproach.fromJson(Map<String, dynamic> json) {
    return HomeApproach(
      eyebrow: (json['eyebrow'] as String?)?.trim() ?? '',
      headline: (json['headline'] as String?)?.trim() ?? '',
      content: (json['content'] as String?)?.trim() ?? '',
      contentHtml: _nonEmpty(json['content_html'] as String?),
      imageUrl: _nonEmpty(json['imageUrl'] as String?),
      buttonLabel: _nonEmpty(json['buttonLabel'] as String?),
      buttonUrl: _nonEmpty(json['buttonUrl'] as String?),
    );
  }
}

class HomeConditionsSection {
  const HomeConditionsSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<HomeLinkCard> items;

  factory HomeConditionsSection.fromJson(Map<String, dynamic> json) {
    return HomeConditionsSection(
      title: (json['title'] as String?)?.trim() ?? 'conditions we treat',
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => HomeLinkCard.fromJson(item.map((k, v) => MapEntry('$k', v))))
          .toList(),
    );
  }
}

class HomeTherapiesSection {
  const HomeTherapiesSection({
    required this.title,
    required this.items,
    this.ctaLabel,
    this.ctaUrl,
  });

  final String title;
  final List<HomeLinkCard> items;
  final String? ctaLabel;
  final String? ctaUrl;

  factory HomeTherapiesSection.fromJson(Map<String, dynamic> json) {
    return HomeTherapiesSection(
      title: (json['title'] as String?)?.trim() ?? 'Featured Therapies',
      ctaLabel: _nonEmpty(json['ctaLabel'] as String?),
      ctaUrl: _nonEmpty(json['ctaUrl'] as String?),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => HomeLinkCard.fromJson(item.map((k, v) => MapEntry('$k', v))))
          .toList(),
    );
  }
}

class HomeLinkCard {
  const HomeLinkCard({
    required this.slug,
    required this.title,
    this.imageUrl,
    this.linkUrl,
    this.summary,
  });

  final String slug;
  final String title;
  final String? imageUrl;
  final String? linkUrl;
  final String? summary;

  factory HomeLinkCard.fromJson(Map<String, dynamic> json) {
    return HomeLinkCard(
      slug: (json['slug'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      imageUrl: _nonEmpty(json['imageUrl'] as String?),
      linkUrl: _nonEmpty(json['linkUrl'] as String?),
      summary: _nonEmpty(json['summary'] as String?),
    );
  }
}

class HomeDoctorsSection {
  const HomeDoctorsSection({
    required this.title,
    required this.intro,
    required this.items,
  });

  final String title;
  final String intro;
  final List<DoctorProfile> items;

  factory HomeDoctorsSection.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ??
        (json['doctors'] as List<dynamic>?) ??
        const [];
    return HomeDoctorsSection(
      title: (json['title'] as String?)?.trim() ?? 'Meet Our Doctors',
      intro: (json['intro'] as String?)?.trim() ?? '',
      items: rawItems.whereType<Map>().map((item) {
        final map = item.map((k, v) => MapEntry('$k', v));
        return DoctorProfile.fromJson({
          ...map,
          'title': map['designation'] ?? map['title'] ?? '',
          'imageUrl': map['imageUrl'] ?? map['image_url'],
          'slug': map['slug'] ?? '',
        });
      }).toList(),
    );
  }
}

class HomeNewsletter {
  const HomeNewsletter({
    required this.headline,
    required this.subtext,
    this.backgroundImageUrl,
    this.buttonLabel,
    this.buttonUrl,
  });

  final String headline;
  final String subtext;
  final String? backgroundImageUrl;
  final String? buttonLabel;
  final String? buttonUrl;

  factory HomeNewsletter.fromJson(Map<String, dynamic> json) {
    return HomeNewsletter(
      headline: (json['headline'] as String?)?.trim() ?? '',
      subtext: (json['subtext'] as String?)?.trim() ?? '',
      backgroundImageUrl: _nonEmpty(json['backgroundImageUrl'] as String?),
      buttonLabel: _nonEmpty(json['buttonLabel'] as String?),
      buttonUrl: _nonEmpty(json['buttonUrl'] as String?),
    );
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
