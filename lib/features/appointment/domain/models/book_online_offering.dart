import 'dart:convert';
import 'dart:math' as math;

import '../clinic_slots.dart';

/// Bookable SKU under a /book-online/ category (Django `BookOnlineService`).
class BookOnlineOffering {
  const BookOnlineOffering({
    required this.slug,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.categorySlug,
    this.description = '',
    this.imageUrl = '',
    this.appointmentTopic = '',
  });

  final String slug;
  final String name;
  final int durationMinutes;
  final double price;
  final String categorySlug;
  final String description;
  final String imageUrl;
  final String appointmentTopic;

  /// Website `data-fixed-slot-count`: ceil(duration/30), capped at 3.
  int get requiredSlots {
    if (durationMinutes <= 0) return 1;
    final raw = (durationMinutes / ClinicSlots.slotMinutes).ceil();
    return math.min(SlotSelectionMax.maxSlots, math.max(1, raw));
  }

  bool get isFree => price <= 0;

  String get durationDisplay {
    final minutes = durationMinutes;
    if (minutes <= 0) return '';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (rem == 0) return hours == 1 ? '1 hour' : '$hours hours';
    final hourBit = hours == 1 ? '1 hour' : '$hours hours';
    return '$hourBit $rem min';
  }

  String get priceDisplay {
    if (price <= 0) return 'Free';
    if (price == price.roundToDouble()) return '\$${price.toInt()}';
    var text = price.toStringAsFixed(2);
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    return '\$$text';
  }

  String get metaLine {
    final parts = <String>[
      if (durationDisplay.isNotEmpty) durationDisplay,
      if (priceDisplay.isNotEmpty) priceDisplay,
    ];
    return parts.join(' | ');
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name': name,
        'duration_minutes': durationMinutes,
        'price': price,
        'category': categorySlug,
        'description': description,
        'image_url': imageUrl,
        'appointment_topic': appointmentTopic,
      };

  factory BookOnlineOffering.fromJson(Map<String, dynamic> json) {
    return BookOnlineOffering(
      slug: '${json['slug'] ?? ''}'.trim(),
      name: '${json['name'] ?? ''}'.trim(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      categorySlug: '${json['category'] ?? json['category_slug'] ?? ''}'.trim(),
      description: '${json['description'] ?? ''}'.trim(),
      imageUrl: '${json['image_url'] ?? json['imageUrl'] ?? ''}'.trim(),
      appointmentTopic:
          '${json['appointment_topic'] ?? json['appointmentTopic'] ?? ''}'
              .trim(),
    );
  }

  String encode() => jsonEncode(toJson());

  static BookOnlineOffering? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final offering = BookOnlineOffering.fromJson(decoded);
      if (offering.slug.isEmpty || offering.name.isEmpty) return null;
      return offering;
    } on Object {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is BookOnlineOffering &&
        other.slug == slug &&
        other.name == name &&
        other.durationMinutes == durationMinutes &&
        other.price == price &&
        other.categorySlug == categorySlug;
  }

  @override
  int get hashCode => Object.hash(slug, name, durationMinutes, price, categorySlug);
}

/// Avoid circular import with [SlotSelection] for required-slot math.
abstract final class SlotSelectionMax {
  static const int maxSlots = 3;
}
