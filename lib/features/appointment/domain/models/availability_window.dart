/// One clinic slot from Django `day_slot_payload`.
class AvailabilitySlot {
  const AvailabilitySlot({
    required this.timeMinutes,
    required this.state,
  });

  final int timeMinutes;
  final String state;

  bool get isAvailable => state == 'available';

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      timeMinutes: (json['time_minutes'] as num).toInt(),
      state: (json['state'] as String?)?.trim() ?? '',
    );
  }
}

/// Public booking window from `GET /appointments/availability/`.
class AvailabilityWindow {
  const AvailabilityWindow({
    required this.service,
    required this.timezone,
    required this.today,
    required this.windowEnd,
    required this.slotMinutes,
    required this.days,
    this.windowDays = 15,
  });

  final String service;
  final String timezone;
  final DateTime today;
  final DateTime windowEnd;
  final int slotMinutes;
  final int windowDays;

  /// Clinic-local calendar days → slots (may be empty list).
  final Map<DateTime, List<AvailabilitySlot>> days;

  factory AvailabilityWindow.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['days'];
    final days = <DateTime, List<AvailabilitySlot>>{};
    if (daysRaw is Map) {
      for (final entry in daysRaw.entries) {
        final key = entry.key.toString();
        final day = DateTime.tryParse(key);
        if (day == null) continue;
        final normalized = DateTime(day.year, day.month, day.day);
        final list = entry.value;
        final slots = <AvailabilitySlot>[];
        if (list is List) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              slots.add(AvailabilitySlot.fromJson(item));
            } else if (item is Map) {
              slots.add(
                AvailabilitySlot.fromJson(
                  item.map((k, v) => MapEntry('$k', v)),
                ),
              );
            }
          }
        }
        days[normalized] = slots;
      }
    }

    DateTime? tryParseDay(Object? raw) {
      if (raw is! String || raw.trim().isEmpty) return null;
      final parsed = DateTime.tryParse(raw.trim());
      if (parsed == null) return null;
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    final today = tryParseDay(json['today']);
    if (today == null) {
      throw const FormatException('AvailabilityWindow today is required.');
    }

    final windowDays = (json['window_days'] as num?)?.toInt() ?? 15;

    // Live Django payload uses `window_days`; older/mock shapes may send `window_end`.
    final windowEnd = tryParseDay(json['window_end']) ??
        today.add(Duration(days: windowDays > 0 ? windowDays - 1 : 0));

    return AvailabilityWindow(
      service: (json['service'] as String?)?.trim() ?? '',
      timezone: (json['timezone'] as String?)?.trim() ?? 'America/New_York',
      today: today,
      windowEnd: windowEnd,
      windowDays: windowDays,
      slotMinutes: (json['slot_minutes'] as num?)?.toInt() ?? 30,
      days: days,
    );
  }

  /// Dates that have at least one selectable slot.
  Set<DateTime> get bookableDates {
    return days.entries
        .where((e) => e.value.any((s) => s.isAvailable))
        .map((e) => e.key)
        .toSet();
  }

  List<AvailabilitySlot> availableSlotsOn(DateTime day) {
    return slotsOn(day).where((s) => s.isAvailable).toList();
  }

  /// All clinic slots for a day (available, pending, booked, busy).
  List<AvailabilitySlot> slotsOn(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return List<AvailabilitySlot>.unmodifiable(
      days[key] ?? const <AvailabilitySlot>[],
    );
  }
}
