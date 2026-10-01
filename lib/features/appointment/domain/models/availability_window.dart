import 'booking_machine.dart';

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
    this.machines = const [],
    this.needsMachine = false,
    this.machineId,
    this.fixedSlotCount,
    this.numberOfSessions = 1,
    this.perVisitMinutes,
    this.dayGap = 0,
  });

  final String service;
  final String timezone;
  final DateTime today;
  final DateTime windowEnd;
  final int slotMinutes;
  final int windowDays;

  /// Clinic-local calendar days → slots (may be empty list).
  final Map<DateTime, List<AvailabilitySlot>> days;

  final List<BookingMachine> machines;
  final bool needsMachine;
  final int? machineId;
  final int? fixedSlotCount;
  final int numberOfSessions;
  final int? perVisitMinutes;
  final int dayGap;

  bool get requiresMachinePicker =>
      needsMachine || machines.length > 1;

  int get effectivePerVisitSlots {
    if (fixedSlotCount != null && fixedSlotCount! > 0) {
      return fixedSlotCount!.clamp(1, 3);
    }
    final minutes = perVisitMinutes ?? slotMinutes;
    if (minutes <= 0) return 1;
    final raw = (minutes / slotMinutes).ceil();
    return raw.clamp(1, 3);
  }

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

    final machinesRaw = json['machines'];
    final machines = <BookingMachine>[];
    if (machinesRaw is List) {
      for (final item in machinesRaw) {
        if (item is Map) {
          final machine = BookingMachine.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (machine.id > 0) machines.add(machine);
        }
      }
    }

    final rawMachineId = json['machine_id'];
    int? machineId;
    if (rawMachineId is num) {
      machineId = rawMachineId.toInt();
    } else if (rawMachineId is String && rawMachineId.trim().isNotEmpty) {
      machineId = int.tryParse(rawMachineId.trim());
    }

    return AvailabilityWindow(
      service: (json['service'] as String?)?.trim() ?? '',
      timezone: (json['timezone'] as String?)?.trim() ?? 'America/New_York',
      today: today,
      windowEnd: windowEnd,
      windowDays: windowDays,
      slotMinutes: (json['slot_minutes'] as num?)?.toInt() ?? 30,
      days: days,
      machines: List.unmodifiable(machines),
      needsMachine: json['needs_machine'] == true,
      machineId: machineId,
      fixedSlotCount: (json['fixed_slot_count'] as num?)?.toInt(),
      numberOfSessions: (json['number_of_sessions'] as num?)?.toInt() ?? 1,
      perVisitMinutes: (json['per_visit_minutes'] as num?)?.toInt(),
      dayGap: (json['day_gap'] as num?)?.toInt() ?? 0,
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
