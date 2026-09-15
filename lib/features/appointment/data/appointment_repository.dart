import '../../../core/network/api_result.dart';
import '../domain/models/appointment_booking_result.dart';
import '../domain/models/appointment_request.dart';
import '../domain/models/availability_window.dart';

/// Appointment networking contract (live Django endpoints).
abstract class AppointmentRepository {
  /// Website calendar/slot map: `GET /appointments/availability/?service=`.
  Future<ApiResult<AvailabilityWindow>> getAvailability({
    required String service,
  });

  /// Public create: `POST /api/v1/appointments/`.
  Future<ApiResult<AppointmentBookingResult>> bookAppointment(
    AppointmentRequest request,
  );
}
