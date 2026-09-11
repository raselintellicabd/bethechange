/// One block of a condition page, in API order.
class ConditionSection {
  const ConditionSection({
    required this.type,
    required this.title,
    this.layout = '',
    this.content = '',
    this.contentHtml,
    this.imageUrl,
    this.imageSide = 'left',
    this.items = const [],
  });

  final String type;
  final String layout;
  final String title;
  final String content;
  final String? contentHtml;
  final String? imageUrl;
  final String imageSide;
  final List<ConditionSectionItem> items;

  bool get imageOnRight => imageSide.trim().toLowerCase() == 'right';

  bool get isBooks => layout.trim().toLowerCase() == 'books';

  /// Benefit chips are title-only cards with no body or image.
  bool get isChipGroup =>
      items.isNotEmpty && items.every((item) => item.isLabelOnly);

  factory ConditionSection.fromJson(Map<String, dynamic> json) {
    return ConditionSection(
      type: _text(json, const ['type']),
      layout: _text(json, const ['layout']),
      title: _text(json, const ['title']),
      content: _text(json, const ['content']),
      contentHtml: _nullableText(json, const ['content_html', 'contentHtml']),
      imageUrl: _url(json, const ['img-url', 'imageUrl', 'heroImage']),
      imageSide: _text(json, const ['image-side', 'imageSide']).isEmpty
          ? 'left'
          : _text(json, const ['image-side', 'imageSide']),
      items: _maps(json['items']).map(ConditionSectionItem.fromJson).toList(),
    );
  }
}

class ConditionSectionItem {
  const ConditionSectionItem({
    required this.title,
    this.content = '',
    this.contentHtml,
    this.imageUrl,
    this.linkUrl,
    this.linkLabel,
  });

  final String title;
  final String content;
  final String? contentHtml;
  final String? imageUrl;
  final String? linkUrl;
  final String? linkLabel;

  bool get isLabelOnly =>
      title.trim().isNotEmpty &&
      content.trim().isEmpty &&
      (contentHtml == null || contentHtml!.trim().isEmpty) &&
      (imageUrl == null || imageUrl!.trim().isEmpty);

  /// In-app contact only. Website and membership paths are not opened.
  String? get inAppContactPath {
    final raw = linkUrl?.trim() ?? '';
    if (raw.isEmpty) return null;
    if (raw.toLowerCase().contains('membership')) return null;
    final uri = Uri.tryParse(raw);
    var path = uri?.path ?? raw;
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    if (path == '/contact') return '/contact';
    return null;
  }

  factory ConditionSectionItem.fromJson(Map<String, dynamic> json) {
    return ConditionSectionItem(
      title: _text(json, const ['title', 'label']),
      content: _text(json, const ['content', 'description']),
      contentHtml: _nullableText(json, const ['content_html', 'contentHtml']),
      imageUrl: _url(json, const ['img-url', 'imageUrl', 'iconUrl', 'coverUrl']),
      linkUrl: _nullableText(json, const ['link-url', 'linkUrl', 'purchaseUrl']),
      linkLabel: _nullableText(json, const ['link-label', 'linkLabel']),
    );
  }
}

String _text(Map<String, dynamic> json, List<String> keys) {
  return _nullableText(json, keys) ?? '';
}

String? _nullableText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = '$value'.trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

String? _url(Map<String, dynamic> json, List<String> keys) {
  return _nullableText(json, keys);
}

List<Map<String, dynamic>> _maps(Object? raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((item) {
    return item.map((key, value) => MapEntry('$key', value));
  }).toList();
}
