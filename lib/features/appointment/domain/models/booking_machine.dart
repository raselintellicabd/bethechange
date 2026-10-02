/// Station from availability `machines[]`.
class BookingMachine {
  const BookingMachine({
    required this.id,
    required this.name,
    this.slug = '',
    this.order = 0,
  });

  final int id;
  final String name;
  final String slug;
  final int order;

  factory BookingMachine.fromJson(Map<String, dynamic> json) {
    return BookingMachine(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: '${json['name'] ?? ''}'.trim(),
      slug: '${json['slug'] ?? ''}'.trim(),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'order': order,
      };
}

/// One scheduled visit in a multi-session booking.
class BookingVisit {
  const BookingVisit({
    required this.date,
    required this.timeMinutes,
    this.slotCount = 1,
  });

  final DateTime date;
  final int timeMinutes;
  final int slotCount;

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'date': dateKey,
        'time_minutes': timeMinutes,
        'slot_count': slotCount,
      };

  factory BookingVisit.fromJson(Map<String, dynamic> json) {
    final rawDate = '${json['date'] ?? ''}'.trim();
    final parsed = DateTime.tryParse(rawDate) ?? DateTime.now();
    return BookingVisit(
      date: DateTime(parsed.year, parsed.month, parsed.day),
      timeMinutes: (json['time_minutes'] as num?)?.toInt() ?? 0,
      slotCount: (json['slot_count'] as num?)?.toInt() ?? 1,
    );
  }
}
