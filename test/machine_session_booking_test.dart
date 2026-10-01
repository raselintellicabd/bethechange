import 'package:bethechange/features/appointment/domain/models/appointment_request.dart';
import 'package:bethechange/features/appointment/domain/models/availability_window.dart';
import 'package:bethechange/features/appointment/domain/models/book_online_offering.dart';
import 'package:bethechange/features/appointment/domain/models/booking_machine.dart';
import 'package:bethechange/features/appointment/domain/models/consultation_mode.dart';
import 'package:bethechange/features/appointment/domain/models/patient_details.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:bethechange/features/appointment/domain/models/time_slot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookOnlineOffering session fields', () {
    test('parses per_visit / sessions / day_gap and requiredSlots', () {
      final offering = BookOnlineOffering.fromJson(const {
        'slug': 'chemotherapy-3-sessions-1-hour-each',
        'name': 'ChemoTherapy 3 sessions (1 hour each)',
        'duration_minutes': 180,
        'per_visit_minutes': 60,
        'number_of_sessions': 3,
        'day_gap': 0,
        'price': 160,
        'category': 'chemotherapy',
      });
      expect(offering.numberOfSessions, 3);
      expect(offering.dayGap, 0);
      expect(offering.requiredSlots, 2);
      expect(offering.isMultiSession, isTrue);
    });
  });

  group('AvailabilityWindow machines', () {
    test('parses machines and needs_machine gate', () {
      final window = AvailabilityWindow.fromJson({
        'service': 'ChemoTherapy 3 sessions (1 hour each)',
        'timezone': 'America/New_York',
        'today': '2026-10-01',
        'window_days': 15,
        'slot_minutes': 30,
        'needs_machine': true,
        'machine_id': null,
        'fixed_slot_count': 2,
        'number_of_sessions': 3,
        'per_visit_minutes': 60,
        'day_gap': 0,
        'machines': [
          {'id': 2, 'name': 'Machine 1', 'order': 0, 'slug': 'machine-1'},
          {'id': 15, 'name': 'Machine 2', 'order': 1, 'slug': 'machine-2'},
        ],
        'days': <String, dynamic>{},
      });
      expect(window.needsMachine, isTrue);
      expect(window.machines, hasLength(2));
      expect(window.requiresMachinePicker, isTrue);
      expect(window.effectivePerVisitSlots, 2);
      expect(window.bookableDates, isEmpty);
    });
  });

  group('AppointmentRequest visits payload', () {
    test('emits visits[] when multi-session', () {
      final request = AppointmentRequest(
        sourceContext: const SourceContext(
          type: SourceContextType.service,
          id: 'chemotherapy',
          name: 'Chemotherapy',
        ),
        offering: BookOnlineOffering.fromJson(const {
          'slug': 'chemotherapy-3-sessions-1-hour-each',
          'name': 'ChemoTherapy 3 sessions (1 hour each)',
          'duration_minutes': 180,
          'per_visit_minutes': 60,
          'number_of_sessions': 3,
          'price': 160,
          'category': 'chemotherapy',
        }),
        slot: TimeSlot.fromAvailability(
          date: DateTime(2026, 10, 1),
          timeMinutes: 600,
        ),
        patient: const PatientDetails(
          name: 'Ada',
          email: 'ada@example.com',
          phone: '555',
          consultationMode: ConsultationMode.inOffice,
        ),
        slotCount: 2,
        machineId: 2,
        visits: [
          BookingVisit(
            date: DateTime(2026, 10, 1),
            timeMinutes: 600,
            slotCount: 2,
          ),
          BookingVisit(
            date: DateTime(2026, 10, 2),
            timeMinutes: 630,
            slotCount: 2,
          ),
          BookingVisit(
            date: DateTime(2026, 10, 3),
            timeMinutes: 600,
            slotCount: 2,
          ),
        ],
      );

      final json = request.toBookJson(paymentSessionId: 'pay_1');
      expect(json['machine_id'], 2);
      expect(json['offering_slug'], 'chemotherapy-3-sessions-1-hour-each');
      expect(json['visits'], hasLength(3));
      expect(json.containsKey('date'), isFalse);
    });
  });
}
