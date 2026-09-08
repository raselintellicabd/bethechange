import '../../../core/network/api_result.dart';
import '../domain/models/appointment_booking_result.dart';
import '../domain/models/appointment_request.dart';
import '../domain/models/time_slot.dart';
import 'appointment_repository.dart';

/// In-memory mock of appointment availability + booking.
///
/// - Weekdays are available (past dates excluded).
/// - Fridays return no time slots (empty-state testing).
/// - Notes equal to `force error` simulate a slot-taken failure.
class MockAppointmentRepository implements AppointmentRepository {
  MockAppointmentRepository({DateTime? now}) : _now = now ?? DateTime.now();

  final DateTime _now;
  int _confirmationCounter = 1000;

  static const _slotHours = <int>[9, 10, 11, 13, 14, 15];

  DateTime get _today => DateTime(_now.year, _now.month, _now.day);

  @override
  Future<ApiResult<List<DateTime>>> getAvailableDates({
    required int year,
    required int month,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final dates = <DateTime>[];

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isWeekday = date.weekday >= DateTime.monday &&
          date.weekday <= DateTime.friday;
      final isFutureOrToday = !date.isBefore(_today);
      if (isWeekday && isFutureOrToday) {
        dates.add(date);
      }
    }

    return ApiSuccess(dates);
  }

  @override
  Future<ApiResult<List<TimeSlot>>> getTimeSlots(DateTime date) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized.isBefore(_today)) {
      return const ApiSuccess(<TimeSlot>[]);
    }

    // Fridays intentionally have no slots for empty-state UX.
    if (normalized.weekday == DateTime.friday) {
      return const ApiSuccess(<TimeSlot>[]);
    }

    final slots = _slotHours.map((hour) {
      final dateTime = DateTime(
        normalized.year,
        normalized.month,
        normalized.day,
        hour,
      );
      final label =
          '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}';
      return TimeSlot(
        id: '${normalized.toIso8601String().split('T').first}-$hour',
        label: label,
        dateTime: dateTime,
      );
    }).toList();

    return ApiSuccess(slots);
  }

  @override
  Future<ApiResult<AppointmentBookingResult>> bookAppointment(
    AppointmentRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    // Deterministic failure hook for QA / forced-error testing.
    if (request.patient.notes.trim().toLowerCase() == 'force error') {
      return const ApiFailure(
        message: 'That time slot was just taken. Please choose another time.',
        statusCode: 409,
      );
    }

    _confirmationCounter += 1;
    return ApiSuccess(
      AppointmentBookingResult(
        confirmationId: 'BTC-$_confirmationCounter',
        request: request,
        bookedAt: _now,
      ),
    );
  }
}
