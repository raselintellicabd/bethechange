import 'doctor_profile.dart';
import 'review.dart';

/// Detail payload from `GET /api/v1/about/{slug}/`.
class AboutPage {
  const AboutPage({
    required this.slug,
    required this.kind,
    required this.path,
    required this.title,
    required this.heroHeading,
    required this.content,
    this.sectionTitle,
    this.contentHtml,
    this.imageUrl,
    this.subtitle,
    this.quote,
    this.quoteAttribution,
    this.videoEmbedUrl,
    this.resourcesIntro,
    this.resources = const [],
    this.values = const [],
    this.principles,
    this.steps = const [],
    this.cta,
    this.doctors,
    this.reviews = const [],
  });

  final String slug;
  final String kind;
  final String path;
  final String title;
  final String heroHeading;
  final String? sectionTitle;
  final String content;
  final String? contentHtml;
  final String? imageUrl;
  final String? subtitle;
  final String? quote;
  final String? quoteAttribution;
  final String? videoEmbedUrl;
  final String? resourcesIntro;
  final List<AboutResource> resources;
  final List<AboutValue> values;
  final AboutPrinciples? principles;
  final List<AboutProcessStep> steps;
  final AboutCta? cta;
  final AboutDoctorsBlock? doctors;
  final List<Review> reviews;

  bool get isPractice => kind == 'practice';
  bool get isNaturopathic => kind == 'naturopathic';
  bool get isIntegrative => kind == 'integrative';
  bool get isProcess => kind == 'process';

  factory AboutPage.fromJson(Map<String, dynamic> json) {
    final doctorsRaw = json['doctors'];
    AboutDoctorsBlock? doctors;
    if (doctorsRaw is Map) {
      doctors = AboutDoctorsBlock.fromJson(
        doctorsRaw.map((k, v) => MapEntry('$k', v)),
      );
    }

    final principlesRaw = json['principles'];
    AboutPrinciples? principles;
    if (principlesRaw is Map) {
      principles = AboutPrinciples.fromJson(
        principlesRaw.map((k, v) => MapEntry('$k', v)),
      );
    }

    final ctaRaw = json['cta'];
    AboutCta? cta;
    if (ctaRaw is Map) {
      cta = AboutCta.fromJson(ctaRaw.map((k, v) => MapEntry('$k', v)));
    }

    return AboutPage(
      slug: (json['slug'] as String?)?.trim() ?? '',
      kind: (json['kind'] as String?)?.trim() ?? '',
      path: (json['path'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      heroHeading: (json['heroHeading'] as String?)?.trim() ??
          (json['title'] as String?)?.trim() ??
          '',
      sectionTitle: _nonEmpty(json['sectionTitle'] as String?),
      content: (json['content'] as String?)?.trim() ?? '',
      contentHtml: _nonEmpty(json['content_html'] as String?),
      imageUrl: _nonEmpty(json['imageUrl'] as String?),
      subtitle: _nonEmpty(json['subtitle'] as String?),
      quote: _nonEmpty(json['quote'] as String?),
      quoteAttribution: _nonEmpty(json['quoteAttribution'] as String?),
      videoEmbedUrl: _nonEmpty(json['videoEmbedUrl'] as String?),
      resourcesIntro: _nonEmpty(json['resourcesIntro'] as String?),
      resources: (json['resources'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AboutResource.fromJson(item.map((k, v) => MapEntry('$k', v))),
          )
          .toList(),
      values: (json['values'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AboutValue.fromJson(item.map((k, v) => MapEntry('$k', v))),
          )
          .toList(),
      principles: principles,
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => AboutProcessStep.fromJson(
              item.map((k, v) => MapEntry('$k', v)),
            ),
          )
          .toList(),
      cta: cta,
      doctors: doctors,
      reviews: (json['reviews'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Review.fromJson(item.map((k, v) => MapEntry('$k', v))))
          .toList(),
    );
  }
}

class AboutResource {
  const AboutResource({required this.label, required this.url});

  final String label;
  final String url;

  factory AboutResource.fromJson(Map<String, dynamic> json) {
    return AboutResource(
      label: (json['label'] as String?)?.trim() ?? '',
      url: (json['url'] as String?)?.trim() ?? '',
    );
  }
}

class AboutValue {
  const AboutValue({
    required this.slug,
    required this.title,
    required this.content,
    this.contentHtml,
    this.imageUrl,
  });

  final String slug;
  final String title;
  final String content;
  final String? contentHtml;
  final String? imageUrl;

  List<String> get bulletLines {
    return content
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  factory AboutValue.fromJson(Map<String, dynamic> json) {
    return AboutValue(
      slug: (json['slug'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      content: (json['content'] as String?)?.trim() ?? '',
      contentHtml: _nonEmpty(json['content_html'] as String?),
      imageUrl: _nonEmpty(json['imageUrl'] as String?),
    );
  }
}

class AboutPrinciples {
  const AboutPrinciples({
    required this.title,
    required this.items,
    this.contentHtml,
    this.imageUrl,
  });

  final String title;
  final List<String> items;
  final String? contentHtml;
  final String? imageUrl;

  factory AboutPrinciples.fromJson(Map<String, dynamic> json) {
    return AboutPrinciples(
      title: (json['title'] as String?)?.trim() ?? 'Naturopathic Principles',
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      contentHtml: _nonEmpty(json['content_html'] as String?),
      imageUrl: _nonEmpty(json['imageUrl'] as String?),
    );
  }
}

class AboutProcessStep {
  const AboutProcessStep({
    required this.slug,
    required this.title,
    required this.layout,
    this.tagline,
    this.summary,
    this.summaryHtml,
    this.items = const [],
  });

  final String slug;
  final String title;
  final String? tagline;
  final String? summary;
  final String? summaryHtml;
  final String layout;
  final List<AboutProcessItem> items;

  factory AboutProcessStep.fromJson(Map<String, dynamic> json) {
    return AboutProcessStep(
      slug: (json['slug'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      tagline: _nonEmpty(json['tagline'] as String?),
      summary: _nonEmpty(json['summary'] as String?),
      summaryHtml: _nonEmpty(json['summaryHtml'] as String?),
      layout: (json['layout'] as String?)?.trim() ?? 'cards',
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => AboutProcessItem.fromJson(
              item.map((k, v) => MapEntry('$k', v)),
            ),
          )
          .toList(),
    );
  }
}

class AboutProcessItem {
  const AboutProcessItem({
    required this.slug,
    required this.title,
    this.content,
    this.contentHtml,
    this.imageUrl,
    this.linkUrl,
  });

  final String slug;
  final String title;
  final String? content;
  final String? contentHtml;
  final String? imageUrl;
  final String? linkUrl;

  String get displayTitle => title
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  factory AboutProcessItem.fromJson(Map<String, dynamic> json) {
    return AboutProcessItem(
      slug: (json['slug'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      content: _nonEmpty(json['content'] as String?),
      contentHtml: _nonEmpty(json['content_html'] as String?),
      imageUrl: _nonEmpty(json['imageUrl'] as String?),
      linkUrl: _nonEmpty(json['linkUrl'] as String?),
    );
  }
}

class AboutCta {
  const AboutCta({
    required this.headline,
    required this.subtext,
    this.phoneLabel,
    this.phone,
    this.bookLabel,
    this.bookUrl,
  });

  final String headline;
  final String subtext;
  final String? phoneLabel;
  final String? phone;
  final String? bookLabel;
  final String? bookUrl;

  factory AboutCta.fromJson(Map<String, dynamic> json) {
    return AboutCta(
      headline: (json['headline'] as String?)?.trim() ?? '',
      subtext: (json['subtext'] as String?)?.trim() ?? '',
      phoneLabel: _nonEmpty(json['phoneLabel'] as String?),
      phone: _nonEmpty(json['phone'] as String?),
      bookLabel: _nonEmpty(json['bookLabel'] as String?),
      bookUrl: _nonEmpty(json['bookUrl'] as String?),
    );
  }
}

class AboutDoctorsBlock {
  const AboutDoctorsBlock({
    required this.title,
    required this.intro,
    required this.items,
  });

  final String title;
  final String intro;
  final List<DoctorProfile> items;

  factory AboutDoctorsBlock.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ??
        (json['doctors'] as List<dynamic>?) ??
        const [];
    return AboutDoctorsBlock(
      title: (json['title'] as String?)?.trim() ?? 'Meet Our Doctors',
      intro: (json['intro'] as String?)?.trim() ?? '',
      items: rawItems.whereType<Map>().map((item) {
        final map = item.map((k, v) => MapEntry('$k', v));
        return DoctorProfile.fromJson({
          ...map,
          'title': map['designation'] ?? map['title'] ?? '',
          'imageUrl': map['imageUrl'] ?? map['image_url'] ?? map['img-url'],
          'slug': map['slug'] ?? '',
        });
      }).toList(),
    );
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
