import 'appointment_request.dart';
import 'consultation_mode.dart';
import 'patient_details.dart';
import 'source_context.dart';
import 'time_slot.dart';

class AppointmentBookingResult {
  const AppointmentBookingResult({
    required this.confirmationId,
    required this.request,
    required this.bookedAt,
    this.status = 'pending',
  });

  /// Django appointment `id` as string.
  final String confirmationId;
  final AppointmentRequest request;
  final DateTime bookedAt;
  final String status;

  bool get isPending => status == 'pending';

  /// Maps `POST /api/v1/appointments/` response.
  factory AppointmentBookingResult.fromCreateResponse(
    Map<String, dynamic> json, {
    required AppointmentRequest request,
  }) {
    final id = json['id'];
    final confirmationId = id == null ? '' : '$id'.trim();
    if (confirmationId.isEmpty) {
      throw const FormatException('Appointment id is required.');
    }

    final createdRaw = json['created_at'] as String? ??
        json['starts_at'] as String? ??
        json['bookedAt'] as String? ??
        DateTime.now().toIso8601String();

    return AppointmentBookingResult(
      confirmationId: confirmationId,
      bookedAt: DateTime.parse(createdRaw),
      status: (json['status'] as String?)?.trim() ?? 'pending',
      request: request,
    );
  }

  factory AppointmentBookingResult.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('request')) {
      return AppointmentBookingResult(
        confirmationId:
            (json['confirmationId'] as String?)?.trim() ?? '${json['id'] ?? ''}',
        bookedAt: DateTime.parse(
          json['bookedAt'] as String? ?? json['created_at'] as String,
        ),
        status: (json['status'] as String?)?.trim() ?? 'pending',
        request: AppointmentRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        ),
      );
    }

    final service = (json['service'] as String?)?.trim() ?? '';
    final startsAt = DateTime.parse(json['starts_at'] as String);
    final timeMinutes = startsAt.hour * 60 + startsAt.minute;
    final request = AppointmentRequest(
      sourceContext: SourceContext(
        type: SourceContextType.other,
        id: '',
        name: service.isEmpty ? 'Appointment' : service,
      ),
      slot: TimeSlot.fromAvailability(
        date: startsAt,
        timeMinutes: timeMinutes,
      ),
      patient: PatientDetails(
        name: (json['full_name'] as String?)?.trim() ?? '',
        email: (json['email'] as String?)?.trim() ?? '',
        phone: (json['phone'] as String?)?.trim() ?? '',
        consultationMode: ConsultationMode.tryParse(
              json['consultation_mode'] as String?,
            ) ??
            ConsultationMode.virtual,
      ),
    );
    return AppointmentBookingResult.fromCreateResponse(json, request: request);
  }

  Map<String, dynamic> toJson() => {
        'confirmationId': confirmationId,
        'bookedAt': bookedAt.toIso8601String(),
        'status': status,
        'request': request.toJson(),
      };
}
