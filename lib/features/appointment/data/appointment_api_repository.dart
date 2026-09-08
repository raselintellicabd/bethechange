import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/appointment_booking_result.dart';
import '../domain/models/appointment_request.dart';
import '../domain/models/time_slot.dart';
import 'appointment_repository.dart';

/// Appointment networking via `/appointments/*` endpoints.
class AppointmentApiRepository implements AppointmentRepository {
  AppointmentApiRepository(this._client);

  final ApiClient _client;

  @override
  Future<ApiResult<List<DateTime>>> getAvailableDates({
    required int year,
    required int month,
  }) {
    return _client.get(
      ApiPaths.appointmentsAvailability,
      queryParameters: {
        'year': year,
        'month': month,
      },
      parser: (data) {
        final map = data as Map<String, dynamic>;
        final dates = (map['dates'] as List<dynamic>? ?? const [])
            .map((raw) => DateTime.parse('$raw'))
            .map((d) => DateTime(d.year, d.month, d.day))
            .toList();
        return dates;
      },
    );
  }

  @override
  Future<ApiResult<List<TimeSlot>>> getTimeSlots(DateTime date) {
    final key =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return _client.get(
      ApiPaths.appointmentsSlots,
      queryParameters: {'date': key},
      parser: (data) {
        final map = data as Map<String, dynamic>;
        return (map['slots'] as List<dynamic>? ?? const [])
            .map((item) => TimeSlot.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  Future<ApiResult<AppointmentBookingResult>> bookAppointment(
    AppointmentRequest request,
  ) {
    return _client.post(
      ApiPaths.appointments,
      data: request.toJson(),
      parser: (data) =>
          AppointmentBookingResult.fromJson(data as Map<String, dynamic>),
    );
  }
}
