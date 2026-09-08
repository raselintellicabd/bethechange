import 'appointment_request.dart';

class AppointmentBookingResult {
  const AppointmentBookingResult({
    required this.confirmationId,
    required this.request,
    required this.bookedAt,
  });

  final String confirmationId;
  final AppointmentRequest request;
  final DateTime bookedAt;

  Map<String, dynamic> toJson() => {
        'confirmationId': confirmationId,
        'bookedAt': bookedAt.toIso8601String(),
        'request': request.toJson(),
      };
}
