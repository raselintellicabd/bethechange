enum AboutBlockType {
  heading,
  paragraph,
  quote,
  bulletList,
  numberedList,
  image,
  callout;

  static AboutBlockType fromJson(String value) {
    return AboutBlockType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AboutBlockType.paragraph,
    );
  }
}

/// A single content block inside an About subtab.
class AboutContentBlock {
  const AboutContentBlock({
    required this.type,
    this.title,
    this.text,
    this.imageUrl,
    this.caption,
    this.items = const [],
  });

  final AboutBlockType type;
  final String? title;
  final String? text;
  final String? imageUrl;
  final String? caption;
  final List<String> items;

  factory AboutContentBlock.fromJson(Map<String, dynamic> json) {
    return AboutContentBlock(
      type: AboutBlockType.fromJson(json['type'] as String? ?? 'paragraph'),
      title: json['title'] as String?,
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      caption: json['caption'] as String?,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}
