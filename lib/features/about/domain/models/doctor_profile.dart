class DoctorProfile {
  const DoctorProfile({
    required this.id,
    required this.name,
    required this.title,
    this.imageUrl,
    this.bio,
    this.aboutHeading,
    this.detailParagraphs = const [],
  });

  final String id;

  /// Display name including credentials (e.g. `Sultana Afrooz, D.O.`).
  final String name;

  /// Designation / specialty line shown on cards and detail.
  final String title;

  final String? imageUrl;

  /// Short blurb (cards / summaries).
  final String? bio;

  /// Detail section heading (e.g. `About Dr. Afrooz`).
  final String? aboutHeading;

  /// Full biography paragraphs for the doctor detail screen.
  final List<String> detailParagraphs;

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    final paragraphs = <String>[];
    final rawParagraphs = json['detailParagraphs'] as List<dynamic>?;
    if (rawParagraphs != null) {
      for (final item in rawParagraphs) {
        final text = item.toString().trim();
        if (text.isNotEmpty) paragraphs.add(text);
      }
    } else {
      final legacy = (json['bio'] as String?)?.trim();
      if (legacy != null && legacy.isNotEmpty) paragraphs.add(legacy);
    }

    return DoctorProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      bio: json['bio'] as String?,
      aboutHeading: json['aboutHeading'] as String?,
      detailParagraphs: paragraphs,
    );
  }
}
