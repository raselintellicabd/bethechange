import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/features/appointment/data/appointment_repository.dart';
import 'package:bethechange/features/appointment/domain/booking_labels.dart';
import 'package:bethechange/features/appointment/domain/clinic_slots.dart';
import 'package:bethechange/features/appointment/domain/models/appointment_booking_result.dart';
import 'package:bethechange/features/appointment/domain/models/appointment_request.dart';
import 'package:bethechange/features/appointment/domain/models/availability_window.dart';
import 'package:bethechange/features/appointment/domain/models/consultation_mode.dart';
import 'package:bethechange/features/appointment/domain/models/patient_details.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:bethechange/features/appointment/domain/models/time_slot.dart';
import 'package:bethechange/features/appointment/presentation/providers/appointment_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

/// Fixture shaped like Django `availability_window_payload()`.
Map<String, dynamic> sampleAvailabilityJson({
  String service = 'Consultation regarding Diabetes',
  String today = '2026-09-08',
  int windowDays = 15,
}) {
  return {
    'ok': true,
    'service': service,
    'timezone': 'America/New_York',
    'today': today,
    'window_days': windowDays,
    'pending_hold_hours': 48,
    'work_start_minutes': 600,
    'work_end_minutes': 1020,
    'slot_minutes': 30,
    'days': {
      '2026-09-08': [
        {'time_minutes': 600, 'state': 'available'},
        {'time_minutes': 630, 'state': 'busy'},
        {'time_minutes': 660, 'state': 'pending'},
      ],
      '2026-09-09': [
        {'time_minutes': 600, 'state': 'available'},
        {'time_minutes': 630, 'state': 'available'},
        {'time_minutes': 660, 'state': 'available'},
        {'time_minutes': 690, 'state': 'available'},
      ],
      '2026-09-11': [
        {'time_minutes': 600, 'state': 'busy'},
        {'time_minutes': 630, 'state': 'booked'},
      ],
      '2026-09-12': <Map<String, dynamic>>[],
      '2026-09-13': <Map<String, dynamic>>[],
    },
  };
}

class _FakeAppointmentRepository implements AppointmentRepository {
  _FakeAppointmentRepository({
    AvailabilityWindow? window,
    this.bookFailureStatus,
    this.bookFailureMessage,
  }) : window = window ??
            AvailabilityWindow.fromJson(sampleAvailabilityJson());

  AvailabilityWindow window;
  final int? bookFailureStatus;
  final String? bookFailureMessage;
  AppointmentRequest? lastRequest;

  @override
  Future<ApiResult<AvailabilityWindow>> getAvailability({
    required String service,
  }) async {
    return ApiSuccess(window);
  }

  @override
  Future<ApiResult<AppointmentBookingResult>> bookAppointment(
    AppointmentRequest request,
  ) async {
    lastRequest = request;
    if (bookFailureStatus != null) {
      return ApiFailure(
        message: bookFailureMessage ?? 'Conflict',
        statusCode: bookFailureStatus,
      );
    }
    return ApiSuccess(
      AppointmentBookingResult(
        confirmationId: '42',
        request: request,
        bookedAt: DateTime(2026, 9, 8, 12),
        status: 'pending',
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('booking labels', () {
    test('condition becomes Consultation regarding …', () {
      const ctx = SourceContext(
        type: SourceContextType.condition,
        id: 'diabetes',
        name: 'Diabetes',
      );
      expect(bookingServiceLabel(ctx), 'Consultation regarding Diabetes');
      expect(
        appointmentForLabel(ctx),
        'Appointment for Consultation regarding Diabetes',
      );
    });

    test('service slug maps to Django SERVICES label', () {
      const ctx = SourceContext(
        type: SourceContextType.service,
        id: 'hyperbaric-oxygen-therapy',
        name: 'HBOT',
      );
      expect(bookingServiceLabel(ctx), 'Hyperbaric Oxygen Therapy');
    });

    test('doctor uses website name without credentials', () {
      const ctx = SourceContext(
        type: SourceContextType.doctor,
        id: 'sultana-afrooz',
        name: 'Sultana Afrooz, D.O.',
      );
      expect(bookingServiceLabel(ctx), 'Sultana Afrooz');
      expect(appointmentForLabel(ctx), 'Appointment for Sultana Afrooz');
    });

    test('unknown sources use General appointment', () {
      const ctx = SourceContext(
        type: SourceContextType.other,
        id: '',
        name: 'Home',
      );
      expect(bookingServiceLabel(ctx), kGeneralAppointmentLabel);
    });
  });

  group('AvailabilityWindow', () {
    test('parses Django days and exposes only available slots', () {
      final window = AvailabilityWindow.fromJson(sampleAvailabilityJson());
      expect(window.timezone, 'America/New_York');
      expect(window.slotMinutes, 30);
      expect(window.windowDays, 15);
      expect(window.windowEnd, DateTime(2026, 9, 22));
      expect(window.bookableDates, contains(DateTime(2026, 9, 8)));
      expect(window.bookableDates, contains(DateTime(2026, 9, 9)));
      expect(window.bookableDates, isNot(contains(DateTime(2026, 9, 11))));
      expect(window.bookableDates, isNot(contains(DateTime(2026, 9, 12))));

      final monday = window.availableSlotsOn(DateTime(2026, 9, 8));
      expect(monday.map((s) => s.timeMinutes), [600]);
      expect(
        window.slotsOn(DateTime(2026, 9, 8)).map((s) => s.state),
        ['available', 'busy', 'pending'],
      );
    });

    test('accepts legacy window_end when window_days is absent', () {
      final window = AvailabilityWindow.fromJson({
        'service': 'General appointment',
        'timezone': 'America/New_York',
        'today': '2026-09-15',
        'window_end': '2026-09-29',
        'slot_minutes': 30,
        'days': {
          '2026-09-15': [
            {'time_minutes': 600, 'state': 'available'},
          ],
        },
      });
      expect(window.windowEnd, DateTime(2026, 9, 29));
    });
  });

  group('ClinicSlots', () {
    test('formats Eastern ISO with DST offset', () {
      final starts = ClinicSlots.toClinicIso8601(
        date: DateTime(2026, 9, 16),
        timeMinutes: 600,
      );
      expect(starts, '2026-09-16T10:00:00-04:00');
      expect(
        ClinicSlots.endIso8601(
          date: DateTime(2026, 9, 16),
          timeMinutes: 600,
        ),
        '2026-09-16T10:30:00-04:00',
      );
    });
  });

  group('create payload', () {
    test('POST body matches Django create fields', () {
      final request = AppointmentRequest(
        sourceContext: const SourceContext(
          type: SourceContextType.condition,
          id: 'diabetes',
          name: 'Diabetes',
        ),
        slot: TimeSlot.fromAvailability(
          date: DateTime(2026, 9, 9),
          timeMinutes: 600,
        ),
        patient: const PatientDetails(
          name: 'Rasel',
          email: 'rase@gmail.com',
          phone: '014525552244',
          consultationMode: ConsultationMode.virtual,
        ),
      );

      expect(request.toCreateJson(), {
        'full_name': 'Rasel',
        'email': 'rase@gmail.com',
        'phone': '014525552244',
        'service': 'Consultation regarding Diabetes',
        'consultation_mode': 'virtual',
        'starts_at': '2026-09-09T10:00:00-04:00',
        'ends_at': '2026-09-09T10:30:00-04:00',
      });
      expect(request.toCreateJson().containsKey('meet_link'), isFalse);
      expect(request.toCreateJson().containsKey('status'), isFalse);
    });

    test('multi-slot POST body extends ends_at', () {
      final request = AppointmentRequest(
        sourceContext: const SourceContext(
          type: SourceContextType.condition,
          id: 'diabetes',
          name: 'Diabetes',
        ),
        slot: TimeSlot.fromAvailability(
          date: DateTime(2026, 9, 9),
          timeMinutes: 600,
        ),
        slotCount: 3,
        patient: const PatientDetails(
          name: 'Rasel',
          email: 'rase@gmail.com',
          phone: '014525552244',
          consultationMode: ConsultationMode.virtual,
        ),
      );

      expect(request.toCreateJson()['starts_at'], '2026-09-09T10:00:00-04:00');
      expect(request.toCreateJson()['ends_at'], '2026-09-09T11:30:00-04:00');
      expect(request.timeRangeLabel, contains('–'));
    });

    test('maps Django create response to pending result', () {
      final request = AppointmentRequest(
        sourceContext: const SourceContext(
          type: SourceContextType.service,
          id: 'frequency-specific-microcurrent',
          name: 'FSM',
        ),
        slot: TimeSlot.fromAvailability(
          date: DateTime(2026, 9, 9),
          timeMinutes: 630,
        ),
        patient: const PatientDetails(
          name: 'Ada',
          email: 'ada@example.com',
          phone: '3015551212',
          consultationMode: ConsultationMode.inOffice,
        ),
      );

      final result = AppointmentBookingResult.fromCreateResponse(
        {
          'id': 7,
          'full_name': 'Ada',
          'email': 'ada@example.com',
          'phone': '3015551212',
          'service': 'Frequency Specific Microcurrent',
          'consultation_mode': 'in_office',
          'meet_link': '',
          'starts_at': '2026-09-09T10:30:00-04:00',
          'ends_at': '2026-09-09T11:00:00-04:00',
          'status': 'pending',
          'created_at': '2026-09-08T12:00:00Z',
          'updated_at': '2026-09-08T12:00:00Z',
        },
        request: request,
      );

      expect(result.confirmationId, '7');
      expect(result.isPending, isTrue);
      expect(result.request.patient.consultationMode, ConsultationMode.inOffice);
    });
  });

  group('AppointmentApiRepository (mock interceptor shape)', () {
    final now = DateTime(2026, 9, 8, 10);
    final repository = createMockAppointmentRepository(now: now);

    test('loads website-shaped availability window', () async {
      final result = await repository.getAvailability(
        service: 'Consultation regarding Diabetes',
      );
      expect(result, isA<ApiSuccess<AvailabilityWindow>>());
      final window = (result as ApiSuccess<AvailabilityWindow>).data;
      expect(window.bookableDates, isNotEmpty);
      expect(
        window.bookableDates.every((d) => d.weekday <= DateTime.friday),
        isTrue,
      );
      expect(window.availableSlotsOn(DateTime(2026, 9, 11)), isEmpty);
    });

    test('books with create payload and returns pending id', () async {
      final slot = TimeSlot.fromAvailability(
        date: DateTime(2026, 9, 9),
        timeMinutes: 600,
      );
      final result = await repository.bookAppointment(
        AppointmentRequest(
          sourceContext: const SourceContext(
            type: SourceContextType.condition,
            id: 'diabetes',
            name: 'Diabetes',
          ),
          slot: slot,
          patient: const PatientDetails(
            name: 'Test Patient',
            email: 'test@example.com',
            phone: '3019709724',
            consultationMode: ConsultationMode.virtual,
          ),
        ),
      );
      expect(result, isA<ApiSuccess>());
      final booking = (result as ApiSuccess<AppointmentBookingResult>).data;
      expect(booking.status, 'pending');
      expect(booking.confirmationId, isNotEmpty);
    });
  });

  group('AppointmentController', () {
    const sourceContext = SourceContext(
      type: SourceContextType.condition,
      id: 'diabetes',
      name: 'Diabetes',
    );

    test('select date then slot enables details step', () async {
      final repository = _FakeAppointmentRepository();
      final controller = AppointmentController(
        repository: repository,
        sourceContext: sourceContext,
        now: DateTime(2026, 9, 8, 10),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.state.availableDates, isNotEmpty);
      expect(
        controller.state.appointmentFor,
        'Appointment for Consultation regarding Diabetes',
      );

      await controller.selectDate(DateTime(2026, 9, 9));
      expect(controller.state.step, AppointmentStep.time);
      expect(
        controller.state.slots.map((s) => s.timeMinutes),
        [600, 630, 660, 690],
      );
      expect(
        controller.state.slots.every((s) => s.state == 'available'),
        isTrue,
      );

      controller.selectSlot(controller.state.slots.first);
      controller.continueToDetails();
      expect(controller.state.step, AppointmentStep.details);

      controller.submitPatientDetails(
        const PatientDetails(
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          phone: '3015551212',
          consultationMode: ConsultationMode.inOffice,
        ),
      );
      expect(controller.state.step, AppointmentStep.confirm);

      await controller.confirmBooking();
      expect(controller.state.step, AppointmentStep.success);
      expect(controller.state.result?.confirmationId, '42');
      expect(
        repository.lastRequest?.toCreateJson()['consultation_mode'],
        'in_office',
      );
    });

    test('fills middle slots and caps selection at 3', () async {
      final repository = _FakeAppointmentRepository();
      final controller = AppointmentController(
        repository: repository,
        sourceContext: sourceContext,
        now: DateTime(2026, 9, 8, 10),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await controller.selectDate(DateTime(2026, 9, 9));
      final slots = controller.state.slots;

      controller.selectSlot(slots[0]); // 10:00
      expect(controller.state.selection?.slotCount, 1);

      controller.selectSlot(slots[2]); // 11:00 → fills 10:30
      expect(controller.state.selection?.startMinutes, 600);
      expect(controller.state.selection?.endMinutes, 690);
      expect(controller.state.selection?.slotCount, 3);
      expect(controller.state.isSlotSelected(slots[1]), isTrue);

      controller.selectSlot(slots[3]); // 11:30 would be 4 slots
      expect(controller.state.selection?.slotCount, 3);
      expect(controller.state.errorMessage, contains('up to 3'));

      controller.continueToDetails();
      controller.submitPatientDetails(
        const PatientDetails(
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          phone: '3015551212',
          consultationMode: ConsultationMode.virtual,
        ),
      );
      await controller.confirmBooking();

      final body = repository.lastRequest!.toCreateJson();
      expect(body['starts_at'], '2026-09-09T10:00:00-04:00');
      expect(body['ends_at'], '2026-09-09T11:30:00-04:00');
      expect(repository.lastRequest!.slotCount, 3);
    });

    test('shows pending/busy slots but only available is selectable', () async {
      final controller = AppointmentController(
        repository: _FakeAppointmentRepository(),
        sourceContext: sourceContext,
        now: DateTime(2026, 9, 8, 10),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await controller.selectDate(DateTime(2026, 9, 8));
      expect(
        controller.state.slots.map((s) => s.state),
        ['available', 'busy', 'pending'],
      );
      expect(controller.state.slots.first.stateLabel, 'Available');
      expect(controller.state.slots[2].stateLabel, 'Pending');

      controller.selectSlot(controller.state.slots[2]); // pending
      expect(controller.state.selectedSlot, isNull);

      controller.selectSlot(controller.state.slots.first);
      expect(controller.state.selectedSlot?.timeMinutes, 600);
    });

    test('conflict reloads availability and returns to time step', () async {
      final repository = _FakeAppointmentRepository(
        bookFailureStatus: 400,
        bookFailureMessage: 'That time slot was just taken.',
      );
      final controller = AppointmentController(
        repository: repository,
        sourceContext: sourceContext,
        now: DateTime(2026, 9, 8, 10),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await controller.selectDate(DateTime(2026, 9, 9));
      controller.selectSlot(controller.state.slots.first);
      controller.continueToDetails();
      controller.submitPatientDetails(
        const PatientDetails(
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          phone: '3015551212',
          consultationMode: ConsultationMode.virtual,
        ),
      );
      await controller.confirmBooking();

      expect(controller.state.step, AppointmentStep.time);
      expect(controller.state.errorMessage, contains('just taken'));
      expect(controller.state.slots, isNotEmpty);
    });

    test('back navigation preserves source context', () async {
      final controller = AppointmentController(
        repository: _FakeAppointmentRepository(),
        sourceContext: sourceContext,
        now: DateTime(2026, 9, 8, 10),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await controller.selectDate(DateTime(2026, 9, 9));
      controller.selectSlot(controller.state.slots.first);
      controller.continueToDetails();
      controller.goBack();

      expect(controller.state.step, AppointmentStep.time);
      expect(controller.state.sourceContext, sourceContext);
      expect(controller.state.selectedDate, DateTime(2026, 9, 9));
    });
  });
}
