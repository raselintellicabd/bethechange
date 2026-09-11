/// A block parsed from a blog article's `content_html`.
sealed class BlogContentBlock {
  const BlogContentBlock();
}

class BlogParagraph extends BlogContentBlock {
  const BlogParagraph(this.text);

  final String text;
}

class BlogHeading extends BlogContentBlock {
  const BlogHeading(this.text, {required this.level});

  final String text;
  final int level;
}

class BlogBulletList extends BlogContentBlock {
  const BlogBulletList(this.items);

  final List<String> items;
}

/// Turns article HTML into headings, paragraphs, and lists.
///
/// Unknown tags are stripped. Falls back to splitting plain [body] when HTML
/// is missing or has no recognizable blocks.
List<BlogContentBlock> blogContentBlocks({
  String? contentHtml,
  String body = '',
  String? subtitle,
}) {
  final html = contentHtml?.trim() ?? '';
  final parsed = html.isEmpty ? const <BlogContentBlock>[] : parseBlogHtml(html);
  final blocks = parsed.isNotEmpty ? parsed : _plainParagraphs(body);
  return _withoutDuplicateLead(blocks, subtitle);
}

List<BlogContentBlock> parseBlogHtml(String html) {
  final source = html.replaceAll('\r\n', '\n');
  final blocks = <BlogContentBlock>[];
  final pattern = RegExp(
    r'<(h([1-6])|p|ul|ol)\b[^>]*>(.*?)</\1>',
    caseSensitive: false,
    dotAll: true,
  );

  var last = 0;
  for (final match in pattern.allMatches(source)) {
    _addLooseText(blocks, source.substring(last, match.start));
    final tag = match.group(1)!.toLowerCase();
    final inner = match.group(3) ?? '';
    if (tag == 'ul' || tag == 'ol') {
      final items = RegExp(
        r'<li\b[^>]*>(.*?)</li>',
        caseSensitive: false,
        dotAll: true,
      )
          .allMatches(inner)
          .map((item) => _plainText(item.group(1) ?? ''))
          .where((item) => item.isNotEmpty)
          .toList();
      if (items.isNotEmpty) blocks.add(BlogBulletList(items));
    } else if (tag.startsWith('h')) {
      final text = _plainText(inner);
      final level = int.tryParse(tag.substring(1)) ?? 3;
      if (text.isNotEmpty) blocks.add(BlogHeading(text, level: level));
    } else {
      final text = _plainText(inner);
      if (text.isNotEmpty) blocks.add(BlogParagraph(text));
    }
    last = match.end;
  }
  _addLooseText(blocks, source.substring(last));
  return blocks;
}

List<BlogContentBlock> _plainParagraphs(String body) {
  return body
      .split(RegExp(r'\n\s*\n'))
      .map(_plainText)
      .where((part) => part.isNotEmpty)
      .map(BlogParagraph.new)
      .toList();
}

void _addLooseText(List<BlogContentBlock> blocks, String raw) {
  final text = _plainText(raw);
  if (text.isEmpty) return;
  blocks.add(BlogParagraph(text));
}

String _plainText(String input) {
  var text = input.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'<[^>]+>'), '');
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
  text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final code = int.tryParse(match.group(1) ?? '');
    if (code == null || code <= 0) return match.group(0)!;
    return String.fromCharCode(code);
  });
  text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  return text.trim();
}

List<BlogContentBlock> _withoutDuplicateLead(
  List<BlogContentBlock> blocks,
  String? subtitle,
) {
  if (blocks.isEmpty) return blocks;
  final lead = subtitle?.trim() ?? '';
  if (lead.isEmpty) return blocks;
  final first = blocks.first;
  if (first is! BlogParagraph) return blocks;
  if (_normalize(first.text) != _normalize(lead)) return blocks;
  return blocks.sublist(1);
}

String _normalize(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
