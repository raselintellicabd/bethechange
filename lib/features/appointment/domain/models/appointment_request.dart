import '../booking_labels.dart';
import '../clinic_slots.dart';
import 'book_online_offering.dart';
import 'patient_details.dart';
import 'source_context.dart';
import 'time_slot.dart';

class AppointmentRequest {
  const AppointmentRequest({
    required this.sourceContext,
    required this.slot,
    required this.patient,
    this.slotCount = 1,
    this.offering,
  });

  final SourceContext sourceContext;

  /// First slot in the selected consecutive range.
  final TimeSlot slot;
  final PatientDetails patient;

  /// Number of 30-minute slots (1–3).
  final int slotCount;

  /// Selected book-online offering when booking from the picker.
  final BookOnlineOffering? offering;

  String get serviceLabel =>
      offering?.name ?? bookingServiceLabel(sourceContext);

  String get timeRangeLabel {
    if (slotCount <= 1) return slot.label;
    final endMinutes =
        slot.timeMinutes + slotCount * ClinicSlots.slotMinutes;
    return '${slot.label} – ${ClinicSlots.displayLabel(endMinutes)}';
  }

  factory AppointmentRequest.fromJson(Map<String, dynamic> json) {
    return AppointmentRequest(
      sourceContext: SourceContext.fromJson(
        json['sourceContext'] as Map<String, dynamic>,
      ),
      slot: TimeSlot.fromJson(json['slot'] as Map<String, dynamic>),
      patient: PatientDetails.fromJson(json['patient'] as Map<String, dynamic>),
      slotCount: (json['slotCount'] as num?)?.toInt() ?? 1,
      offering: json['offering'] is Map<String, dynamic>
          ? BookOnlineOffering.fromJson(
              json['offering'] as Map<String, dynamic>,
            )
          : null,
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
        'ends_at': ClinicSlots.endIso8601(
          date: slot.date,
          timeMinutes: slot.timeMinutes,
          durationMinutes: slotCount * ClinicSlots.slotMinutes,
        ),
      };

  Map<String, dynamic> toJson() => {
        'sourceContext': sourceContext.toJson(),
        'slot': slot.toJson(),
        'patient': patient.toJson(),
        'service': serviceLabel,
        'slotCount': slotCount,
        if (offering != null) 'offering': offering!.toJson(),
      };
}
