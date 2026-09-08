import 'about_content_block.dart';

/// One About subtab (Our Practice, Naturopathic, Integrative, Our Process).
class AboutSection {
  const AboutSection({
    required this.id,
    required this.title,
    required this.blocks,
    this.showDoctors = false,
    this.showReviews = false,
  });

  final String id;
  final String title;
  final List<AboutContentBlock> blocks;
  final bool showDoctors;
  final bool showReviews;

  factory AboutSection.fromJson(Map<String, dynamic> json) {
    return AboutSection(
      id: json['id'] as String,
      title: json['title'] as String,
      showDoctors: json['showDoctors'] as bool? ?? false,
      showReviews: json['showReviews'] as bool? ?? false,
      blocks: (json['blocks'] as List<dynamic>? ?? const [])
          .map((item) => AboutContentBlock.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
