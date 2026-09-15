import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/appointment_booking_result.dart';
import '../domain/models/appointment_request.dart';
import '../domain/models/availability_window.dart';
import 'appointment_repository.dart';

/// Live appointment APIs (website availability + v1 create).
class AppointmentApiRepository implements AppointmentRepository {
  AppointmentApiRepository(this._client);

  final ApiClient _client;

  @override
  Future<ApiResult<AvailabilityWindow>> getAvailability({
    required String service,
  }) {
    return _client.get(
      ApiPaths.appointmentsAvailability,
      queryParameters: {'service': service},
      parser: (data) =>
          AvailabilityWindow.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResult<AppointmentBookingResult>> bookAppointment(
    AppointmentRequest request,
  ) {
    return _client.post(
      ApiPaths.appointments,
      data: request.toCreateJson(),
      parser: (data) => AppointmentBookingResult.fromCreateResponse(
        data as Map<String, dynamic>,
        request: request,
      ),
    );
  }
}
