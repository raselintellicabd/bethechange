import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/features/appointment/domain/models/appointment_request.dart';
import 'package:bethechange/features/appointment/domain/models/patient_details.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:bethechange/features/appointment/domain/models/time_slot.dart';
import 'package:bethechange/features/appointment/presentation/providers/appointment_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 8, 10); // Monday
  final repository = createMockAppointmentRepository(now: now);

  const sourceContext = SourceContext(
    type: SourceContextType.condition,
    id: 'diabetes',
    name: 'Diabetes',
  );

  group('AppointmentApiRepository', () {
    test('returns weekday availability excluding past dates', () async {
      final result = await repository.getAvailableDates(year: 2026, month: 9);
      expect(result, isA<ApiSuccess<List<DateTime>>>());
      final dates = (result as ApiSuccess<List<DateTime>>).data;

      expect(dates, isNotEmpty);
      expect(dates.every((d) => d.weekday <= DateTime.friday), isTrue);
      expect(dates.every((d) => !d.isBefore(DateTime(2026, 9, 8))), isTrue);
    });

    test('Fridays return empty slot lists', () async {
      final friday = DateTime(2026, 9, 11);
      final result = await repository.getTimeSlots(friday);
      expect(result, isA<ApiSuccess<List<TimeSlot>>>());
      expect((result as ApiSuccess<List<TimeSlot>>).data, isEmpty);
    });

    test('booking payload includes sourceContext and succeeds', () async {
      final slots =
          ((await repository.getTimeSlots(DateTime(2026, 9, 9)))
                  as ApiSuccess<List<TimeSlot>>)
              .data;
      final request = AppointmentRequest(
        sourceContext: sourceContext,
        slot: slots.first,
        patient: const PatientDetails(
          name: 'Test Patient',
          email: 'test@example.com',
          phone: '3019709724',
        ),
      );

      final result = await repository.bookAppointment(request);
      expect(result, isA<ApiSuccess>());
      final booking = (result as ApiSuccess).data;
      expect(booking.request.sourceContext, sourceContext);
      expect(booking.request.toJson()['sourceContext'], sourceContext.toJson());
      expect(booking.confirmationId, startsWith('BTC-'));
    });

    test('force error notes simulate slot-taken failure', () async {
      final slots =
          ((await repository.getTimeSlots(DateTime(2026, 9, 9)))
                  as ApiSuccess<List<TimeSlot>>)
              .data;
      final result = await repository.bookAppointment(
        AppointmentRequest(
          sourceContext: sourceContext,
          slot: slots.first,
          patient: const PatientDetails(
            name: 'Test Patient',
            email: 'test@example.com',
            phone: '3019709724',
            notes: 'force error',
          ),
        ),
      );

      expect(result, isA<ApiFailure>());
      expect((result as ApiFailure).statusCode, 409);
    });
  });

  group('AppointmentController', () {
    test('select date then slot enables details step', () async {
      final controller = AppointmentController(
        repository: repository,
        sourceContext: sourceContext,
        now: now,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.state.availableDates, isNotEmpty);

      final date = controller.state.availableDates
          .firstWhere((d) => d.weekday != DateTime.friday);
      await controller.selectDate(date);
      expect(controller.state.step, AppointmentStep.time);
      expect(controller.state.slots, isNotEmpty);

      controller.selectSlot(controller.state.slots.first);
      controller.continueToDetails();
      expect(controller.state.step, AppointmentStep.details);

      controller.submitPatientDetails(
        const PatientDetails(
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          phone: '3015551212',
        ),
      );
      expect(controller.state.step, AppointmentStep.confirm);

      await controller.confirmBooking();
      expect(controller.state.step, AppointmentStep.success);
      expect(controller.state.result?.request.sourceContext.id, 'diabetes');
    });

    test('back navigation preserves source context', () async {
      final controller = AppointmentController(
        repository: repository,
        sourceContext: sourceContext,
        now: now,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final date = controller.state.availableDates
          .firstWhere((d) => d.weekday != DateTime.friday);
      await controller.selectDate(date);
      controller.selectSlot(controller.state.slots.first);
      controller.continueToDetails();
      controller.goBack();

      expect(controller.state.step, AppointmentStep.time);
      expect(controller.state.sourceContext, sourceContext);
      expect(controller.state.selectedDate, date);
    });
  });
}
