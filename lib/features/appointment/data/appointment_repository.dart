import '../../../core/network/api_result.dart';
import '../domain/models/appointment_booking_result.dart';
import '../domain/models/appointment_request.dart';
import '../domain/models/availability_window.dart';
import '../domain/models/book_online_catalog.dart';

/// Appointment networking contract (live Django endpoints).
abstract class AppointmentRepository {
  /// Website calendar/slot map: `GET /appointments/availability/?service=`.
  Future<ApiResult<AvailabilityWindow>> getAvailability({
    required String service,
  });

  /// Book-online catalog: `GET /api/v1/book-online/`.
  Future<ApiResult<BookOnlineCatalog>> getBookOnlineCatalog();

  /// Public create: `POST /api/v1/appointments/`.
  Future<ApiResult<AppointmentBookingResult>> bookAppointment(
    AppointmentRequest request,
  );
}
