class HomeContent {
  const HomeContent({
    required this.heroTag,
    required this.heroTitle,
    this.aboutSegmentLabels = const {},
    this.sectionImages = const {},
  });

  final String heroTag;
  final String heroTitle;
  final Map<String, String> aboutSegmentLabels;
  final Map<String, String> sectionImages;

  String segmentLabel(String id, String fallbackTitle) {
    final label = aboutSegmentLabels[id];
    if (label != null && label.trim().isNotEmpty) return label;
    final parts = fallbackTitle.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? fallbackTitle : parts.first;
  }

  String? sectionImageUrl(String id) {
    final url = sectionImages[id]?.trim();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  factory HomeContent.fromJson(Map<String, dynamic> json) {
    final rawLabels = json['aboutSegmentLabels'];
    final labels = <String, String>{};
    if (rawLabels is Map) {
      for (final entry in rawLabels.entries) {
        labels['${entry.key}'] = '${entry.value}';
      }
    }

    final rawImages = json['sectionImages'];
    final images = <String, String>{};
    if (rawImages is Map) {
      for (final entry in rawImages.entries) {
        images['${entry.key}'] = '${entry.value}';
      }
    }

    return HomeContent(
      heroTag: (json['heroTag'] as String?)?.trim() ?? '',
      heroTitle: (json['heroTitle'] as String?)?.trim() ?? '',
      aboutSegmentLabels: labels,
      sectionImages: images,
    );
  }
}
