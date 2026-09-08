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

  factory AppointmentRequest.fromJson(Map<String, dynamic> json) {
    return AppointmentRequest(
      sourceContext: SourceContext.fromJson(
        json['sourceContext'] as Map<String, dynamic>,
      ),
      slot: TimeSlot.fromJson(json['slot'] as Map<String, dynamic>),
      patient: PatientDetails.fromJson(json['patient'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceContext': sourceContext.toJson(),
        'slot': slot.toJson(),
        'patient': patient.toJson(),
        'scheduledAt': slot.dateTime.toIso8601String(),
      };
}
