import 'package:intl/intl.dart';

/// Clinic-local slot helpers aligned with Django `appointments.availability`.
abstract final class ClinicSlots {
  static const String timezoneName = 'America/New_York';
  static const int slotMinutes = 30;

  /// Format a clinic-local civil time as ISO-8601 with America/New_York offset.
  ///
  /// US Eastern: EDT (UTC−4) second Sunday in March → first Sunday in November;
  /// otherwise EST (UTC−5).
  static String toClinicIso8601({
    required DateTime date,
    required int timeMinutes,
  }) {
    final hour = timeMinutes ~/ 60;
    final minute = timeMinutes % 60;
    final offset = _easternOffset(date);
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$y-$m-${d}T$hh:$mm:00$offset';
  }

  static String endIso8601({
    required DateTime date,
    required int timeMinutes,
    int durationMinutes = slotMinutes,
  }) {
    return toClinicIso8601(
      date: date,
      timeMinutes: timeMinutes + durationMinutes,
    );
  }

  static String displayLabel(int timeMinutes) {
    final hour = timeMinutes ~/ 60;
    final minute = timeMinutes % 60;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat.jm().format(dt);
  }

  static String _easternOffset(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final dstStart = _nthWeekdayOfMonth(date.year, 3, DateTime.sunday, 2);
    final dstEnd = _nthWeekdayOfMonth(date.year, 11, DateTime.sunday, 1);
    final inDst = !day.isBefore(dstStart) && day.isBefore(dstEnd);
    return inDst ? '-04:00' : '-05:00';
  }

  static DateTime _nthWeekdayOfMonth(
    int year,
    int month,
    int weekday,
    int n,
  ) {
    var count = 0;
    for (var day = 1; day <= 31; day++) {
      final candidate = DateTime(year, month, day);
      if (candidate.month != month) break;
      if (candidate.weekday == weekday) {
        count++;
        if (count == n) return DateTime(year, month, day);
      }
    }
    throw StateError('Weekday not found');
  }
}
