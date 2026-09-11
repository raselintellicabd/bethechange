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

    final name = (json['name'] as String?)?.trim() ?? '';
    final explicitId = _id(json['id']);
    final title = (json['title'] as String?)?.trim() ??
        (json['designation'] as String?)?.trim() ??
        '';
    final imageUrl = (json['imageUrl'] as String?)?.trim() ??
        (json['img-url'] as String?)?.trim();

    return DoctorProfile(
      id: (explicitId != null && explicitId.isNotEmpty)
          ? explicitId
          : slugFromName(name),
      name: name,
      title: title,
      imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
      bio: json['bio'] as String?,
      aboutHeading: json['aboutHeading'] as String?,
      detailParagraphs: paragraphs,
    );
  }

  static String? _id(Object? raw) {
    if (raw == null) return null;
    final text = '$raw'.trim();
    return text.isEmpty ? null : text;
  }

  /// Turns `Sultana Afrooz, D.O.` into `sultana-afrooz`.
  static String slugFromName(String name) {
    final base = name.split(',').first.trim().toLowerCase();
    final slug = base
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'doctor' : slug;
  }
}
