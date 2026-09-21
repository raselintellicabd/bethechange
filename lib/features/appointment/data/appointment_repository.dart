import '../../../core/network/api_result.dart';
import '../domain/models/appointment_booking_result.dart';
import '../domain/models/appointment_request.dart';
import '../domain/models/availability_window.dart';
import '../domain/models/book_online_catalog.dart';
import '../domain/models/booking_quote.dart';

/// Appointment networking contract (live Django endpoints).
abstract class AppointmentRepository {
  Future<ApiResult<AvailabilityWindow>> getAvailability({
    required String service,
  });

  Future<ApiResult<BookOnlineCatalog>> getBookOnlineCatalog();

  Future<ApiResult<BookingQuote>> getQuote({
    required String service,
    String? offeringSlug,
  });

  Future<ApiResult<PaymentSessionResult>> createPaymentSession({
    required String service,
    String? offeringSlug,
  });

  Future<ApiResult<void>> confirmPayment({
    required String paymentSessionId,
    required String clientSecret,
    required Map<String, dynamic> paymentMethod,
  });

  Future<ApiResult<AppointmentBookingResult>> bookAppointment({
    required AppointmentRequest request,
    required String paymentSessionId,
  });
}
