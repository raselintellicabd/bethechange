import '../../../about/domain/models/about_content_block.dart';
import '../../../about/domain/models/about_section.dart';
import '../../../about/domain/models/doctor_profile.dart';
import '../../../about/domain/models/review.dart';

/// Parsed GET `/api/v1/home/` payload, ready for [HomeContent].
class HomeApiPayload {
  const HomeApiPayload({
    required this.sections,
    required this.doctors,
    required this.reviews,
    required this.aboutSegmentLabels,
    required this.sectionImages,
  });

  final List<AboutSection> sections;
  final List<DoctorProfile> doctors;
  final List<Review> reviews;
  final Map<String, String> aboutSegmentLabels;
  final Map<String, String> sectionImages;
}

/// Maps GET `/api/v1/home/` JSON onto the home screen models.
class HomeApiMapper {
  HomeApiMapper._();

  static const sectionSpecs = <({String apiKey, String id, String label})>[
    (apiKey: 'practice', id: 'our-practice', label: 'Practice'),
    (apiKey: 'naturopathic', id: 'naturopathic-medicine', label: 'Naturopathic'),
    (
      apiKey: 'Integrative-medicine',
      id: 'integrative-medicine',
      label: 'Integrative',
    ),
    (apiKey: 'our-process', id: 'our-process', label: 'Process'),
  ];

  static HomeApiPayload parse(Map<String, dynamic> json) {
    final sections = <AboutSection>[];
    final labels = <String, String>{};
    final images = <String, String>{};

    for (final spec in sectionSpecs) {
      final raw =
          _asMap(json[spec.apiKey]) ?? _mapByKeyIgnoreCase(json, spec.apiKey);
      if (raw == null) continue;

      final title = _titleCase(_string(raw, 'title') ?? spec.label);
      final imageUrl = _string(raw, 'img-url') ?? _string(raw, 'imageUrl');
      if (imageUrl != null) images[spec.id] = imageUrl;
      labels[spec.id] = spec.label;

      final blocks = blocksFromPlainContent(
        _string(raw, 'content') ?? '',
        quote: _string(raw, 'quote'),
        heading: title,
      );

      if (spec.id == 'our-practice') {
        blocks.addAll(_practiceCallouts(json));
      }

      sections.add(
        AboutSection(
          id: spec.id,
          title: title,
          showDoctors: true,
          showReviews: true,
          blocks: blocks,
        ),
      );
    }

    return HomeApiPayload(
      sections: sections,
      doctors: _list(json['doctors']).map(DoctorProfile.fromJson).toList(),
      reviews: _list(json['reviews']).map(Review.fromJson).toList(),
      aboutSegmentLabels: labels,
      sectionImages: images,
    );
  }

  static List<AboutContentBlock> blocksFromPlainContent(
    String content, {
    String? quote,
    String? heading,
  }) {
    final blocks = <AboutContentBlock>[];
    final headingText = heading?.trim();
    if (headingText != null && headingText.isNotEmpty) {
      blocks.add(
        AboutContentBlock(type: AboutBlockType.heading, title: headingText),
      );
    }

    final chunks = content.split(RegExp(r'\n\s*\n'));
    for (final rawChunk in chunks) {
      final lines = rawChunk
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;

      if (headingText != null &&
          lines.length == 1 &&
          _normalize(lines.single) == _normalize(headingText)) {
        continue;
      }

      if (lines.length == 1) {
        if (_isHeading(lines.single)) {
          blocks.add(
            AboutContentBlock(
              type: AboutBlockType.heading,
              title: _cleanHeading(lines.single),
            ),
          );
        } else {
          blocks.add(
            AboutContentBlock(
              type: AboutBlockType.paragraph,
              text: lines.single,
            ),
          );
        }
        continue;
      }

      if (_isListChunk(lines)) {
        blocks.add(
          AboutContentBlock(type: AboutBlockType.bulletList, items: lines),
        );
        continue;
      }

      if (_isHeading(lines.first)) {
        blocks.add(
          AboutContentBlock(
            type: AboutBlockType.heading,
            title: _cleanHeading(lines.first),
          ),
        );
        final rest = lines.skip(1).toList();
        if (rest.isEmpty) continue;
        if (_isListChunk(rest)) {
          blocks.add(
            AboutContentBlock(type: AboutBlockType.bulletList, items: rest),
          );
        } else {
          blocks.add(
            AboutContentBlock(
              type: AboutBlockType.paragraph,
              text: rest.join('\n'),
            ),
          );
        }
        continue;
      }

      blocks.add(
        AboutContentBlock(type: AboutBlockType.paragraph, text: lines.join('\n')),
      );
    }

    final quoteBlock = quoteBlockFrom(quote);
    if (quoteBlock != null) blocks.add(quoteBlock);
    return blocks;
  }

  static AboutContentBlock? quoteBlockFrom(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    String? caption;
    final bodyLines = <String>[];
    for (final part in trimmed.split(RegExp(r'\n+'))) {
      final line = part.trim();
      if (line.isEmpty) continue;
      if (bodyLines.isNotEmpty &&
          (line.startsWith('-') ||
              line.startsWith('—') ||
              line.startsWith('–'))) {
        caption = line.replaceFirst(RegExp(r'^[-—–]\s*'), '').trim();
      } else {
        bodyLines.add(line);
      }
    }

    var text = bodyLines.join(' ').trim();
    text = text
        .replaceFirst(RegExp(r'^[“”"‘’]+'), '')
        .replaceFirst(RegExp(r'[“”"‘’]+$'), '')
        .trim();
    if (text.isEmpty) return null;

    return AboutContentBlock(
      type: AboutBlockType.quote,
      text: text,
      caption: caption,
    );
  }

  static List<AboutContentBlock> _practiceCallouts(Map<String, dynamic> json) {
    final blocks = <AboutContentBlock>[];
    final vision = _string(json, 'our-vision');
    if (vision != null) {
      blocks.add(
        AboutContentBlock(
          type: AboutBlockType.callout,
          title: 'Our Vision',
          text: vision,
        ),
      );
    }

    final goal = _string(json, 'our-goal');
    if (goal != null) {
      blocks.add(
        AboutContentBlock(
          type: AboutBlockType.callout,
          title: 'Our Goal',
          text: goal,
        ),
      );
    }

    final values = _string(json, 'core-values');
    if (values != null) {
      final items = values
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      if (items.isNotEmpty) {
        blocks.add(
          AboutContentBlock(
            type: AboutBlockType.bulletList,
            title: 'Our Core Values',
            items: items,
          ),
        );
      }
    }

    return blocks;
  }

  static bool _isHeading(String line) {
    final text = line.trim();
    if (text.isEmpty || text.length > 90) return false;
    if (text.toLowerCase().startsWith('http')) return false;
    if (RegExp(r'^STEP\s*#?\d+', caseSensitive: false).hasMatch(text)) {
      return true;
    }
    if (text.endsWith('?') && text.length <= 80) return true;
    if (text.endsWith('.') || text.contains('. ')) return false;
    return text.split(RegExp(r'\s+')).length <= 12;
  }

  static bool _isListChunk(List<String> lines) {
    if (lines.length < 2) return false;
    return lines.every((line) {
      if (line.length > 80) return false;
      if (line.contains('. ')) return false;
      if (line.endsWith('.') && line.length > 40) return false;
      return _isHeading(line) || !line.contains('.');
    });
  }

  static String _cleanHeading(String line) {
    return line.trim();
  }

  static String _titleCase(String input) {
    return input.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      final lower = word.toLowerCase();
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).join(' ');
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  static String? _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic>? _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return null;
  }

  static Map<String, dynamic>? _mapByKeyIgnoreCase(
    Map<String, dynamic> json,
    String key,
  ) {
    final target = key.toLowerCase();
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() != target) continue;
      return _asMap(entry.value);
    }
    return null;
  }

  static List<Map<String, dynamic>> _list(Object? raw) {
    if (raw is! List) return const [];
    return raw.map(_asMap).whereType<Map<String, dynamic>>().toList();
  }
}
