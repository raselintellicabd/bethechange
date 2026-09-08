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

  factory AppointmentBookingResult.fromJson(Map<String, dynamic> json) {
    final confirmationId = (json['confirmationId'] as String?)?.trim() ?? '';
    if (confirmationId.isEmpty) {
      throw const FormatException('confirmationId is required.');
    }
    return AppointmentBookingResult(
      confirmationId: confirmationId,
      bookedAt: DateTime.parse(json['bookedAt'] as String),
      request: AppointmentRequest.fromJson(
        json['request'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'confirmationId': confirmationId,
        'bookedAt': bookedAt.toIso8601String(),
        'request': request.toJson(),
      };
}
