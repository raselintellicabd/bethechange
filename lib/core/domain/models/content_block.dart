/// Shared rich-text/image block used by Conditions and Services detail pages.
class ContentBlock {
  const ContentBlock({
    required this.title,
    this.body,
    this.imageUrl,
  });

  final String title;
  final String? body;
  final String? imageUrl;

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String?)?.trim() ?? '';
    if (title.isEmpty) {
      throw const FormatException('ContentBlock title is required.');
    }

    return ContentBlock(
      title: title,
      body: json['body'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        if (body != null) 'body': body,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}
