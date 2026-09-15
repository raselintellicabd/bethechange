import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../data/appointment_api_repository.dart';
import '../../data/appointment_repository.dart';
import '../../domain/booking_labels.dart';
import '../../domain/models/appointment_booking_result.dart';
import '../../domain/models/appointment_request.dart';
import '../../domain/models/availability_window.dart';
import '../../domain/models/patient_details.dart';
import '../../domain/models/source_context.dart';
import '../../domain/models/time_slot.dart';

enum AppointmentStep { date, time, details, confirm, success }

class AppointmentBookingState {
  const AppointmentBookingState({
    required this.sourceContext,
    this.step = AppointmentStep.date,
    required this.focusedMonth,
    this.availability,
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
  final AvailabilityWindow? availability;
  final Set<DateTime> availableDates;
  final DateTime? selectedDate;
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final PatientDetails? patient;
  final bool isLoading;
  final String? errorMessage;
  final AppointmentBookingResult? result;

  String get bookingLabel => bookingServiceLabel(sourceContext);

  String get appointmentFor => appointmentForLabel(sourceContext);

  bool isDateAvailable(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return availableDates.contains(normalized);
  }

  AppointmentBookingState copyWith({
    AppointmentStep? step,
    DateTime? focusedMonth,
    AvailabilityWindow? availability,
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
      availability: availability ?? this.availability,
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
  return AppointmentApiRepository(ref.watch(apiClientProvider));
});

final appointmentControllerProvider = StateNotifierProvider.autoDispose
    .family<AppointmentController, AppointmentBookingState, SourceContext>(
  (ref, sourceContext) {
    return AppointmentController(
      repository: ref.watch(appointmentRepositoryProvider),
      sourceContext: sourceContext,
      analytics: ref.watch(analyticsServiceProvider),
    );
  },
);

class AppointmentController extends StateNotifier<AppointmentBookingState> {
  AppointmentController({
    required this._repository,
    required SourceContext sourceContext,
    AnalyticsService? analytics,
    DateTime? now,
  })  : _analytics = analytics ?? const LoggingAnalyticsService(),
        _now = now ?? DateTime.now(),
        super(
          AppointmentBookingState(
            sourceContext: sourceContext,
            focusedMonth: DateTime(
              (now ?? DateTime.now()).year,
              (now ?? DateTime.now()).month,
            ),
          ),
        ) {
    _analytics.logEvent(
      AnalyticsEvents.appointmentStarted,
      parameters: {
        'type': sourceContext.type.name,
        'id': sourceContext.id,
      },
    );
    loadAvailability();
  }

  final AppointmentRepository _repository;
  final AnalyticsService _analytics;
  final DateTime _now;

  Future<void> loadAvailability() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getAvailability(
      service: state.bookingLabel,
    );

    result.when(
      success: (window) {
        var focused = DateTime(state.focusedMonth.year, state.focusedMonth.month);
        final minMonth = DateTime(window.today.year, window.today.month);
        final maxMonth =
            DateTime(window.windowEnd.year, window.windowEnd.month);
        if (focused.isBefore(minMonth)) focused = minMonth;
        if (focused.isAfter(maxMonth)) focused = maxMonth;

        state = state.copyWith(
          availability: window,
          focusedMonth: focused,
          availableDates: _datesForMonth(window, focused),
          isLoading: false,
        );
      },
      failure: (message, _) {
        state = state.copyWith(isLoading: false, errorMessage: message);
      },
    );
  }

  Future<void> loadMonth(DateTime month) async {
    final window = state.availability;
    var focused = DateTime(month.year, month.month);

    if (window != null) {
      final minMonth = DateTime(window.today.year, window.today.month);
      final maxMonth = DateTime(window.windowEnd.year, window.windowEnd.month);
      if (focused.isBefore(minMonth)) focused = minMonth;
      if (focused.isAfter(maxMonth)) focused = maxMonth;

      state = state.copyWith(
        focusedMonth: focused,
        availableDates: _datesForMonth(window, focused),
        clearError: true,
      );
      return;
    }

    state = state.copyWith(focusedMonth: focused);
    await loadAvailability();
  }

  Set<DateTime> _datesForMonth(AvailabilityWindow window, DateTime month) {
    final year = month.year;
    final monthNum = month.month;
    return window.bookableDates
        .where((d) => d.year == year && d.month == monthNum)
        .toSet();
  }

  Future<void> selectDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    if (!state.isDateAvailable(normalized)) return;

    final window = state.availability;
    if (window == null) {
      await loadAvailability();
      return;
    }

    final slots = window
        .slotsOn(normalized)
        .map(
          (s) => TimeSlot.fromAvailability(
            date: normalized,
            timeMinutes: s.timeMinutes,
            state: s.state,
          ),
        )
        .toList();

    state = state.copyWith(
      selectedDate: normalized,
      clearSelectedSlot: true,
      slots: slots,
      step: AppointmentStep.time,
      clearError: true,
    );
  }

  void selectSlot(TimeSlot slot) {
    if (!slot.isSelectable) return;
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
    if (result is ApiSuccess<AppointmentBookingResult>) {
      final booking = result.data;
      _analytics.logEvent(
        AnalyticsEvents.appointmentCompleted,
        parameters: {
          'type': state.sourceContext.type.name,
          'id': state.sourceContext.id,
          'bookingId': booking.confirmationId,
        },
      );
      state = state.copyWith(
        isLoading: false,
        result: booking,
        step: AppointmentStep.success,
      );
      return;
    }

    final failure = result as ApiFailure<AppointmentBookingResult>;
    final message = failure.message;
    final statusCode = failure.statusCode;
    state = state.copyWith(isLoading: false, errorMessage: message);

    if (statusCode == 400 || statusCode == 409) {
      await loadAvailability();
      final selected = state.selectedDate;
      if (selected != null && state.isDateAvailable(selected)) {
        await selectDate(selected);
        state = state.copyWith(
          step: AppointmentStep.time,
          errorMessage: message,
        );
      } else {
        state = state.copyWith(
          step: AppointmentStep.date,
          clearSelectedDate: true,
          clearSelectedSlot: true,
          slots: const [],
          errorMessage: message,
        );
      }
    }
  }

  void retryAfterError() {
    state = state.copyWith(clearError: true);
  }

  DateTime get now => _now;
}
