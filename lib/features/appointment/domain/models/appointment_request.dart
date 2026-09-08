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

  Map<String, dynamic> toJson() => {
        'sourceContext': sourceContext.toJson(),
        'slot': slot.toJson(),
        'patient': patient.toJson(),
        'scheduledAt': slot.dateTime.toIso8601String(),
      };
}
