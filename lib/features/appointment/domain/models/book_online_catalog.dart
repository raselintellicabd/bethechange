import 'book_online_offering.dart';

class BookOnlineCategory {
  const BookOnlineCategory({
    required this.slug,
    required this.name,
    this.offerings = const [],
  });

  final String slug;
  final String name;
  final List<BookOnlineOffering> offerings;

  BookOnlineCategory copyWithOfferings(List<BookOnlineOffering> offerings) {
    return BookOnlineCategory(
      slug: slug,
      name: name,
      offerings: offerings,
    );
  }

  factory BookOnlineCategory.fromJson(Map<String, dynamic> json) {
    return BookOnlineCategory(
      slug: '${json['slug'] ?? ''}'.trim(),
      name: '${json['name'] ?? ''}'.trim(),
    );
  }
}

/// Full /book-online/ catalog (categories + nested offerings).
class BookOnlineCatalog {
  const BookOnlineCatalog({required this.categories});

  final List<BookOnlineCategory> categories;

  /// Category whose offerings map to a CMS service page slug via
  /// `appointment_topic`, or whose category slug matches.
  BookOnlineCategory? categoryForCmsTopic(String cmsSlug) {
    final topic = cmsSlug.trim();
    if (topic.isEmpty) return null;

    for (final category in categories) {
      final matched = category.offerings
          .where((o) => o.appointmentTopic == topic)
          .toList();
      if (matched.isNotEmpty) {
        return category.copyWithOfferings(matched);
      }
    }

    for (final category in categories) {
      if (category.slug == topic) {
        return category;
      }
    }
    return null;
  }

  BookOnlineOffering? offeringBySlug(String slug) {
    for (final category in categories) {
      for (final offering in category.offerings) {
        if (offering.slug == slug) return offering;
      }
    }
    return null;
  }

  factory BookOnlineCatalog.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'] as List<dynamic>? ?? const [];

    // Nested API shape: categories[].offerings[]
    if (rawCategories.isNotEmpty &&
        rawCategories.first is Map &&
        (rawCategories.first as Map).containsKey('offerings')) {
      final fromNested = <BookOnlineCategory>[];
      for (final raw in rawCategories) {
        if (raw is! Map) continue;
        final map = raw.map((k, v) => MapEntry('$k', v));
        final slug = '${map['slug'] ?? ''}'.trim();
        final name = '${map['name'] ?? ''}'.trim();
        if (slug.isEmpty) continue;
        final offerings = (map['offerings'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((o) {
              final om = o.map((k, v) => MapEntry('$k', v));
              om.putIfAbsent('category', () => slug);
              return BookOnlineOffering.fromJson(om);
            })
            .where((o) => o.slug.isNotEmpty && o.name.isNotEmpty)
            .toList();
        fromNested.add(
          BookOnlineCategory(slug: slug, name: name, offerings: offerings),
        );
      }
      return BookOnlineCatalog(categories: fromNested);
    }

    // Flat seed shape: categories[] + services[] with category slug.
    final categoryRows = rawCategories
        .whereType<Map>()
        .map((e) => BookOnlineCategory.fromJson(
              e.map((k, v) => MapEntry('$k', v)),
            ))
        .where((c) => c.slug.isNotEmpty)
        .toList();

    final offeringsByCategory = <String, List<BookOnlineOffering>>{
      for (final c in categoryRows) c.slug: <BookOnlineOffering>[],
    };

    final serviceRows = (json['services'] as List<dynamic>? ?? const [])
        .whereType<Map>();
    for (final raw in serviceRows) {
      final map = raw.map((k, v) => MapEntry('$k', v));
      final offering = BookOnlineOffering.fromJson(map);
      if (offering.slug.isEmpty || offering.name.isEmpty) continue;
      final list = offeringsByCategory[offering.categorySlug];
      if (list == null) continue;
      list.add(offering);
    }

    final nested = categoryRows
        .map(
          (c) => c.copyWithOfferings(
            List<BookOnlineOffering>.unmodifiable(
              offeringsByCategory[c.slug] ?? const [],
            ),
          ),
        )
        .toList();

    return BookOnlineCatalog(categories: nested);
  }
}
