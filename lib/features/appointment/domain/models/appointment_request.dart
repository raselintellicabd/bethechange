import '../booking_labels.dart';
import '../clinic_slots.dart';
import 'book_online_offering.dart';
import 'booking_machine.dart';
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
    this.machineId,
    this.visits = const [],
  });

  final SourceContext sourceContext;

  /// First slot in the selected consecutive range (legacy / primary visit).
  final TimeSlot slot;
  final PatientDetails patient;

  /// Number of 30-minute slots for the primary visit (1–3).
  final int slotCount;

  /// Selected book-online offering when booking from the picker.
  final BookOnlineOffering? offering;

  /// Selected machine/station when the service requires one.
  final int? machineId;

  /// Multi-session visits (when length > 1, sent as `visits[]`).
  final List<BookingVisit> visits;

  String get serviceLabel =>
      offering?.name ?? bookingServiceLabel(sourceContext);

  String get timeRangeLabel {
    if (visits.length > 1) {
      return '${visits.length} sessions';
    }
    if (slotCount <= 1) return slot.label;
    final endMinutes =
        slot.timeMinutes + slotCount * ClinicSlots.slotMinutes;
    return '${slot.label} – ${ClinicSlots.displayLabel(endMinutes)}';
  }

  factory AppointmentRequest.fromJson(Map<String, dynamic> json) {
    final visitsRaw = json['visits'];
    final visits = <BookingVisit>[];
    if (visitsRaw is List) {
      for (final item in visitsRaw) {
        if (item is Map) {
          visits.add(BookingVisit.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
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
      machineId: (json['machineId'] as num?)?.toInt() ??
          (json['machine_id'] as num?)?.toInt(),
      visits: visits,
    );
  }

  /// Payload for `POST /api/v1/appointments/book/`.
  Map<String, dynamic> toBookJson({
    required String paymentSessionId,
  }) {
    final date = slot.date;
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final body = <String, dynamic>{
      'full_name': patient.name,
      'email': patient.email,
      'phone': patient.phone,
      'service': serviceLabel,
      'consultation_mode': patient.consultationMode.apiValue,
      'payment_session_id': paymentSessionId,
      'for_family_member': patient.forFamilyMember,
      if (offering != null) 'offering_slug': offering!.slug,
      if (machineId != null) 'machine_id': machineId,
    };
    if (visits.length > 1) {
      body['visits'] = visits.map((v) => v.toJson()).toList();
    } else {
      body['date'] = dateStr;
      body['time_minutes'] = slot.timeMinutes;
      body['slot_count'] = slotCount;
    }
    return body;
  }

  /// Payload for legacy `POST /api/v1/appointments/`.
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
        if (machineId != null) 'machineId': machineId,
        if (visits.isNotEmpty) 'visits': visits.map((v) => v.toJson()).toList(),
      };
}
