import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/appointment_booking_result.dart';
import '../domain/models/appointment_history_item.dart';
import '../domain/models/appointment_request.dart';
import '../domain/models/availability_window.dart';
import '../domain/models/book_online_catalog.dart';
import '../domain/models/booking_quote.dart';
import 'appointment_repository.dart';

/// Live appointment APIs (availability + paid book flow).
class AppointmentApiRepository implements AppointmentRepository {
  AppointmentApiRepository(this._client);

  final ApiClient _client;

  @override
  Future<ApiResult<AvailabilityWindow>> getAvailability({
    required String service,
    bool forPackage = false,
  }) {
    return _client.get(
      ApiPaths.appointmentsAvailability,
      queryParameters: {
        'service': service,
        if (forPackage) 'package': '1',
      },
      parser: (data) =>
          AvailabilityWindow.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResult<BookOnlineCatalog>> getBookOnlineCatalog() {
    return _client.get(
      ApiPaths.bookOnline,
      parser: (data) =>
          BookOnlineCatalog.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResult<BookingQuote>> getQuote({
    required String service,
    String? offeringSlug,
  }) {
    return _client.get(
      ApiPaths.appointmentsQuote,
      queryParameters: {
        'service': service,
        if (offeringSlug != null && offeringSlug.isNotEmpty)
          'offering_slug': offeringSlug,
      },
      parser: (data) => BookingQuote.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResult<PaymentSessionResult>> createPaymentSession({
    required String service,
    String? offeringSlug,
  }) {
    return _client.post(
      ApiPaths.appointmentsPaymentSession,
      data: {
        'service': service,
        if (offeringSlug != null && offeringSlug.isNotEmpty)
          'offering_slug': offeringSlug,
      },
      parser: (data) =>
          PaymentSessionResult.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResult<void>> confirmPayment({
    required String paymentSessionId,
    required String clientSecret,
    required Map<String, dynamic> paymentMethod,
  }) {
    return _client.post(
      ApiPaths.appointmentsPaymentConfirm,
      data: {
        'payment_session_id': paymentSessionId,
        'client_secret': clientSecret,
        'payment_method': paymentMethod,
      },
      parser: (_) {},
    );
  }

  @override
  Future<ApiResult<AppointmentBookingResult>> bookAppointment({
    required AppointmentRequest request,
    required String paymentSessionId,
  }) {
    return _client.post(
      ApiPaths.appointmentsBook,
      data: request.toBookJson(paymentSessionId: paymentSessionId),
      parser: (data) => AppointmentBookingResult.fromCreateResponse(
        data as Map<String, dynamic>,
        request: request,
      ),
    );
  }

  Future<ApiResult<List<AppointmentHistoryItem>>> fetchHistory() {
    return _client.get(
      ApiPaths.appointmentsHistory,
      parser: (data) {
        final map = data as Map<String, dynamic>;
        final raw = map['results'] as List<dynamic>? ?? const [];
        return raw
            .whereType<Map>()
            .map(
              (item) => AppointmentHistoryItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      },
    );
  }
}
