import 'package:intl/intl.dart';

import '../clinic_slots.dart';

/// Selectable clinic slot derived from availability `time_minutes` + `state`.
class TimeSlot {
  const TimeSlot({
    required this.date,
    required this.timeMinutes,
    required this.label,
    this.state = 'available',
  });

  /// Clinic-local calendar day (date only).
  final DateTime date;

  /// Minutes from midnight (e.g. 600 → 10:00).
  final int timeMinutes;

  final String label;

  /// Django slot state: `available` | `pending` | `booked` | `busy`.
  final String state;

  bool get isSelectable => state == 'available';

  /// Website-style status shown after the time (e.g. Available, Pending).
  String get stateLabel {
    return switch (state) {
      'available' => 'Available',
      'pending' => 'Pending',
      'booked' => 'Booked',
      'busy' => 'Busy',
      _ => state.isEmpty ? 'Unavailable' : state,
    };
  }

  String get id =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}-'
      '$timeMinutes';

  /// Local DateTime used only for display formatting.
  DateTime get dateTime => DateTime(
        date.year,
        date.month,
        date.day,
        timeMinutes ~/ 60,
        timeMinutes % 60,
      );

  String get startsAtIso => ClinicSlots.toClinicIso8601(
        date: date,
        timeMinutes: timeMinutes,
      );

  String get endsAtIso => ClinicSlots.endIso8601(
        date: date,
        timeMinutes: timeMinutes,
      );

  factory TimeSlot.fromAvailability({
    required DateTime date,
    required int timeMinutes,
    String state = 'available',
  }) {
    final day = DateTime(date.year, date.month, date.day);
    return TimeSlot(
      date: day,
      timeMinutes: timeMinutes,
      label: ClinicSlots.displayLabel(timeMinutes),
      state: state,
    );
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    final timeMinutes = (json['timeMinutes'] as num).toInt();
    return TimeSlot(
      date: DateTime(date.year, date.month, date.day),
      timeMinutes: timeMinutes,
      label: (json['label'] as String?)?.trim().isNotEmpty == true
          ? (json['label'] as String).trim()
          : ClinicSlots.displayLabel(timeMinutes),
      state: (json['state'] as String?)?.trim() ?? 'available',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'timeMinutes': timeMinutes,
        'label': label,
        'state': state,
      };

  @override
  bool operator ==(Object other) =>
      other is TimeSlot &&
      other.date == date &&
      other.timeMinutes == timeMinutes;

  @override
  int get hashCode => Object.hash(date, timeMinutes);
}
