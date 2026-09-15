import '../booking_labels.dart';
import 'patient_details.dart';
import 'source_context.dart';
import 'time_slot.dart';

class AppointmentRequest {
  const AppointmentRequest({
    required this.sourceContext,
    required this.slot,
    required this.patient,
  });

  final SourceContext sourceContext;
  final TimeSlot slot;
  final PatientDetails patient;

  String get serviceLabel => bookingServiceLabel(sourceContext);

  factory AppointmentRequest.fromJson(Map<String, dynamic> json) {
    return AppointmentRequest(
      sourceContext: SourceContext.fromJson(
        json['sourceContext'] as Map<String, dynamic>,
      ),
      slot: TimeSlot.fromJson(json['slot'] as Map<String, dynamic>),
      patient: PatientDetails.fromJson(json['patient'] as Map<String, dynamic>),
    );
  }

  /// Payload for `POST /api/v1/appointments/`.
  Map<String, dynamic> toCreateJson() => {
        'full_name': patient.name,
        'email': patient.email,
        'phone': patient.phone,
        'service': serviceLabel,
        'consultation_mode': patient.consultationMode.apiValue,
        'starts_at': slot.startsAtIso,
        'ends_at': slot.endsAtIso,
      };

  Map<String, dynamic> toJson() => {
        'sourceContext': sourceContext.toJson(),
        'slot': slot.toJson(),
        'patient': patient.toJson(),
        'service': serviceLabel,
      };
}
