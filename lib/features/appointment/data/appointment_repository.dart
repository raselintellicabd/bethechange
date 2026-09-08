import '../../../core/network/api_result.dart';
import '../domain/models/appointment_booking_result.dart';
import '../domain/models/appointment_request.dart';
import '../domain/models/time_slot.dart';

/// Appointment networking contract. Mocked until the real API is ready.
abstract class AppointmentRepository {
  Future<ApiResult<List<DateTime>>> getAvailableDates({
    required int year,
    required int month,
  });

  Future<ApiResult<List<TimeSlot>>> getTimeSlots(DateTime date);

  Future<ApiResult<AppointmentBookingResult>> bookAppointment(
    AppointmentRequest request,
  );
}
