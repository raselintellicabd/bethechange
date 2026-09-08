import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/appointment_repository.dart';
import '../../data/mock_appointment_repository.dart';
import '../../domain/models/appointment_booking_result.dart';
import '../../domain/models/appointment_request.dart';
import '../../domain/models/patient_details.dart';
import '../../domain/models/source_context.dart';
import '../../domain/models/time_slot.dart';

enum AppointmentStep { date, time, details, confirm, success }

class AppointmentBookingState {
  const AppointmentBookingState({
    required this.sourceContext,
    this.step = AppointmentStep.date,
    required this.focusedMonth,
    this.availableDates = const {},
    this.selectedDate,
    this.slots = const [],
    this.selectedSlot,
    this.patient,
    this.isLoading = false,
    this.errorMessage,
    this.result,
  });

  final SourceContext sourceContext;
  final AppointmentStep step;
  final DateTime focusedMonth;
  final Set<DateTime> availableDates;
  final DateTime? selectedDate;
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final PatientDetails? patient;
  final bool isLoading;
  final String? errorMessage;
  final AppointmentBookingResult? result;

  bool isDateAvailable(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return availableDates.contains(normalized);
  }

  AppointmentBookingState copyWith({
    AppointmentStep? step,
    DateTime? focusedMonth,
    Set<DateTime>? availableDates,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    List<TimeSlot>? slots,
    TimeSlot? selectedSlot,
    bool clearSelectedSlot = false,
    PatientDetails? patient,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    AppointmentBookingResult? result,
  }) {
    return AppointmentBookingState(
      sourceContext: sourceContext,
      step: step ?? this.step,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      availableDates: availableDates ?? this.availableDates,
      selectedDate:
          clearSelectedDate ? null : selectedDate ?? this.selectedDate,
      slots: slots ?? this.slots,
      selectedSlot:
          clearSelectedSlot ? null : selectedSlot ?? this.selectedSlot,
      patient: patient ?? this.patient,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      result: result ?? this.result,
    );
  }
}

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return MockAppointmentRepository();
});

final appointmentControllerProvider = StateNotifierProvider.autoDispose
    .family<AppointmentController, AppointmentBookingState, SourceContext>(
  (ref, sourceContext) {
    return AppointmentController(
      repository: ref.watch(appointmentRepositoryProvider),
      sourceContext: sourceContext,
    );
  },
);

class AppointmentController extends StateNotifier<AppointmentBookingState> {
  AppointmentController({
    required this._repository,
    required SourceContext sourceContext,
    DateTime? now,
  })  : _now = now ?? DateTime.now(),
        super(
          AppointmentBookingState(
            sourceContext: sourceContext,
            focusedMonth: DateTime(
              (now ?? DateTime.now()).year,
              (now ?? DateTime.now()).month,
            ),
          ),
        ) {
    loadMonth(state.focusedMonth);
  }

  final AppointmentRepository _repository;
  final DateTime _now;

  Future<void> loadMonth(DateTime month) async {
    final focused = DateTime(month.year, month.month);
    state = state.copyWith(
      focusedMonth: focused,
      isLoading: true,
      clearError: true,
    );

    final result = await _repository.getAvailableDates(
      year: focused.year,
      month: focused.month,
    );

    result.when(
      success: (dates) {
        final normalized = dates
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet();
        state = state.copyWith(
          availableDates: normalized,
          isLoading: false,
        );
      },
      failure: (message, _) {
        state = state.copyWith(isLoading: false, errorMessage: message);
      },
    );
  }

  Future<void> selectDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    if (!state.isDateAvailable(normalized)) return;

    state = state.copyWith(
      selectedDate: normalized,
      clearSelectedSlot: true,
      slots: const [],
      step: AppointmentStep.time,
      isLoading: true,
      clearError: true,
    );

    final result = await _repository.getTimeSlots(normalized);
    result.when(
      success: (slots) {
        state = state.copyWith(slots: slots, isLoading: false);
      },
      failure: (message, _) {
        state = state.copyWith(isLoading: false, errorMessage: message);
      },
    );
  }

  void selectSlot(TimeSlot slot) {
    state = state.copyWith(selectedSlot: slot, clearError: true);
  }

  void continueToDetails() {
    if (state.selectedSlot == null) return;
    state = state.copyWith(step: AppointmentStep.details, clearError: true);
  }

  void submitPatientDetails(PatientDetails patient) {
    state = state.copyWith(
      patient: patient,
      step: AppointmentStep.confirm,
      clearError: true,
    );
  }

  void goBack() {
    switch (state.step) {
      case AppointmentStep.time:
        state = state.copyWith(
          step: AppointmentStep.date,
          clearSelectedSlot: true,
          slots: const [],
          clearError: true,
        );
        return;
      case AppointmentStep.details:
        state = state.copyWith(step: AppointmentStep.time, clearError: true);
        return;
      case AppointmentStep.confirm:
        state = state.copyWith(step: AppointmentStep.details, clearError: true);
        return;
      case AppointmentStep.date:
      case AppointmentStep.success:
        return;
    }
  }

  Future<void> confirmBooking() async {
    final slot = state.selectedSlot;
    final patient = state.patient;
    if (slot == null || patient == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final request = AppointmentRequest(
      sourceContext: state.sourceContext,
      slot: slot,
      patient: patient,
    );

    final result = await _repository.bookAppointment(request);
    result.when(
      success: (booking) {
        state = state.copyWith(
          isLoading: false,
          result: booking,
          step: AppointmentStep.success,
        );
      },
      failure: (message, _) {
        state = state.copyWith(isLoading: false, errorMessage: message);
      },
    );
  }

  void retryAfterError() {
    state = state.copyWith(clearError: true);
    if (state.step == AppointmentStep.confirm) {
      // Keep selections; user can confirm again or go back to pick another slot.
    }
  }

  DateTime get now => _now;
}
