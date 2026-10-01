import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../points_offers/presentation/providers/points_offers_providers.dart';
import '../../data/appointment_api_repository.dart';
import '../../data/appointment_repository.dart';
import '../../domain/booking_labels.dart';
import '../../domain/booking_schedule_state.dart';
import '../../domain/clinic_slots.dart';
import '../../domain/models/appointment_booking_result.dart';
import '../../domain/models/appointment_history_item.dart';
import '../../domain/models/appointment_request.dart';
import '../../domain/models/availability_window.dart';
import '../../domain/models/book_online_catalog.dart';
import '../../domain/models/book_online_offering.dart';
import '../../domain/models/booking_machine.dart';
import '../../domain/models/booking_quote.dart';
import '../../domain/models/patient_details.dart';
import '../../domain/models/slot_selection.dart';
import '../../domain/models/source_context.dart';
import '../../domain/models/time_slot.dart';

enum AppointmentStep {
  date,
  time,
  details,
  confirm,
  payment,
  paymentOtp,
  success,
}

/// Route args for the appointment wizard (source page + optional offering).
@immutable
class AppointmentBookingArgs {
  const AppointmentBookingArgs({
    required this.sourceContext,
    this.offering,
  });

  final SourceContext sourceContext;
  final BookOnlineOffering? offering;

  @override
  bool operator ==(Object other) {
    return other is AppointmentBookingArgs &&
        other.sourceContext == sourceContext &&
        other.offering == offering;
  }

  @override
  int get hashCode => Object.hash(sourceContext, offering);
}

class AppointmentBookingState {
  const AppointmentBookingState({
    required this.sourceContext,
    this.offering,
    this.step = AppointmentStep.date,
    required this.focusedMonth,
    this.availability,
    this.availableDates = const {},
    this.selectedDate,
    this.slots = const [],
    this.selection,
    this.machines = const [],
    this.selectedMachineId,
    this.visits = const [],
    this.activeSessionIndex = 0,
    this.numberOfSessions = 1,
    this.dayGap = 0,
    this.patient,
    this.quote,
    this.paymentEmail = '',
    this.cardNumber = '',
    this.cardExpiry = '',
    this.cardCvc = '',
    this.paymentSessionId,
    this.paymentClientSecret,
    this.isLoading = false,
    this.errorMessage,
    this.result,
  });

  final SourceContext sourceContext;
  final BookOnlineOffering? offering;
  final AppointmentStep step;
  final DateTime focusedMonth;
  final AvailabilityWindow? availability;
  final Set<DateTime> availableDates;
  final DateTime? selectedDate;
  final List<TimeSlot> slots;
  final SlotSelection? selection;
  final List<BookingMachine> machines;
  final int? selectedMachineId;
  final List<BookingVisit> visits;
  final int activeSessionIndex;
  final int numberOfSessions;
  final int dayGap;
  final PatientDetails? patient;
  final BookingQuote? quote;
  final String paymentEmail;
  final String cardNumber;
  final String cardExpiry;
  final String cardCvc;
  final String? paymentSessionId;
  final String? paymentClientSecret;
  final bool isLoading;
  final String? errorMessage;
  final AppointmentBookingResult? result;

  bool get hasFixedDuration =>
      offering != null ||
      (availability?.fixedSlotCount != null &&
          (availability!.fixedSlotCount ?? 0) > 0);

  int? get requiredSlotCount {
    if (availability?.fixedSlotCount != null &&
        availability!.fixedSlotCount! > 0) {
      return availability!.effectivePerVisitSlots;
    }
    return offering?.requiredSlots;
  }

  bool get requiresMachinePicker =>
      machines.length > 1 || (availability?.needsMachine ?? false);

  bool get calendarUnlocked =>
      !requiresMachinePicker || selectedMachineId != null;

  bool get isMultiSession => numberOfSessions > 1;

  bool get isScheduleComplete => visits.length >= numberOfSessions;

  String get bookingLabel =>
      bookingServiceLabel(sourceContext, offering: offering);

  String get appointmentFor =>
      appointmentForLabel(sourceContext, offering: offering);

  String get payableLabel =>
      quote?.payableDisplay ?? offering?.priceDisplay ?? '—';

  /// First slot of the selected range (for booking payload).
  TimeSlot? get selectedSlot {
    if (visits.isNotEmpty) {
      final first = visits.first;
      return TimeSlot.fromAvailability(
        date: first.date,
        timeMinutes: first.timeMinutes,
      );
    }
    final range = selection;
    if (range == null) return null;
    for (final slot in slots) {
      if (slot.timeMinutes == range.startMinutes) return slot;
    }
    return null;
  }

  int get selectedSlotCount {
    if (visits.isNotEmpty) return visits.first.slotCount;
    return selection?.slotCount ?? 0;
  }

  String? get selectionTimeLabel {
    if (visits.length > 1) return '${visits.length} sessions scheduled';
    if (visits.length == 1) {
      final v = visits.first;
      final start = ClinicSlots.displayLabel(v.timeMinutes);
      if (v.slotCount <= 1) return start;
      final end = ClinicSlots.displayLabel(
        v.timeMinutes + v.slotCount * ClinicSlots.slotMinutes,
      );
      return '$start – $end';
    }
    return selection?.timeRangeLabel;
  }

  String? get selectedMachineName {
    final id = selectedMachineId;
    if (id == null) return null;
    for (final m in machines) {
      if (m.id == id) return m.name;
    }
    return null;
  }

  bool isDateAvailable(DateTime day) {
    final window = availability;
    if (window == null) {
      return visitIndexForDate(visits, day) >= 0 || availableDates.contains(
        DateTime(day.year, day.month, day.day),
      );
    }
    return isScheduleDateAvailable(
      day: day,
      visits: visits,
      activeSessionIndex: activeSessionIndex,
      dayGap: dayGap,
      bookableDates: {
        ...window.bookableDates,
        ...availableDates,
      },
    );
  }

  bool isSlotSelected(TimeSlot slot) =>
      selection?.containsSlot(slot) ?? false;

  AppointmentBookingState copyWith({
    AppointmentStep? step,
    DateTime? focusedMonth,
    AvailabilityWindow? availability,
    Set<DateTime>? availableDates,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    List<TimeSlot>? slots,
    SlotSelection? selection,
    bool clearSelection = false,
    List<BookingMachine>? machines,
    int? selectedMachineId,
    bool clearMachine = false,
    List<BookingVisit>? visits,
    int? activeSessionIndex,
    int? numberOfSessions,
    int? dayGap,
    PatientDetails? patient,
    BookingQuote? quote,
    bool clearQuote = false,
    String? paymentEmail,
    String? cardNumber,
    String? cardExpiry,
    String? cardCvc,
    String? paymentSessionId,
    String? paymentClientSecret,
    bool clearPaymentSession = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    AppointmentBookingResult? result,
  }) {
    return AppointmentBookingState(
      sourceContext: sourceContext,
      offering: offering,
      step: step ?? this.step,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      availability: availability ?? this.availability,
      availableDates: availableDates ?? this.availableDates,
      selectedDate:
          clearSelectedDate ? null : selectedDate ?? this.selectedDate,
      slots: slots ?? this.slots,
      selection: clearSelection ? null : selection ?? this.selection,
      machines: machines ?? this.machines,
      selectedMachineId:
          clearMachine ? null : selectedMachineId ?? this.selectedMachineId,
      visits: visits ?? this.visits,
      activeSessionIndex: activeSessionIndex ?? this.activeSessionIndex,
      numberOfSessions: numberOfSessions ?? this.numberOfSessions,
      dayGap: dayGap ?? this.dayGap,
      patient: patient ?? this.patient,
      quote: clearQuote ? null : quote ?? this.quote,
      paymentEmail: paymentEmail ?? this.paymentEmail,
      cardNumber: cardNumber ?? this.cardNumber,
      cardExpiry: cardExpiry ?? this.cardExpiry,
      cardCvc: cardCvc ?? this.cardCvc,
      paymentSessionId: clearPaymentSession
          ? null
          : paymentSessionId ?? this.paymentSessionId,
      paymentClientSecret: clearPaymentSession
          ? null
          : paymentClientSecret ?? this.paymentClientSecret,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      result: result ?? this.result,
    );
  }
}

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentApiRepository(ref.watch(apiClientProvider));
});

final appointmentHistoryProvider =
    FutureProvider.autoDispose<List<AppointmentHistoryItem>>((ref) async {
  final repo = AppointmentApiRepository(ref.watch(apiClientProvider));
  final result = await repo.fetchHistory();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});

final bookOnlineCatalogProvider =
    FutureProvider.autoDispose<BookOnlineCatalog>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  final result = await repository.getBookOnlineCatalog();
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure(:final message) =>
      throw Exception(message.isEmpty ? 'Unable to load services.' : message),
  };
});

final appointmentControllerProvider = StateNotifierProvider.autoDispose
    .family<AppointmentController, AppointmentBookingState, AppointmentBookingArgs>(
  (ref, args) {
    return AppointmentController(
      repository: ref.watch(appointmentRepositoryProvider),
      sourceContext: args.sourceContext,
      offering: args.offering,
      analytics: ref.watch(analyticsServiceProvider),
      onPointsAwarded: (awarded) async {
        if (awarded > 0) {
          await ref.read(authControllerProvider.notifier).addPoints(awarded);
        } else {
          await ref.read(authControllerProvider.notifier).refreshProfile();
        }
        ref.invalidate(pointsOfferCatalogProvider);
      },
    );
  },
);

class AppointmentController extends StateNotifier<AppointmentBookingState> {
  AppointmentController({
    required this._repository,
    required SourceContext sourceContext,
    BookOnlineOffering? offering,
    AnalyticsService? analytics,
    DateTime? now,
    this.paymentDelay = const Duration(milliseconds: 600),
    Future<void> Function(int pointsAwarded)? onPointsAwarded,
  })  : _analytics = analytics ?? const LoggingAnalyticsService(),
        _now = now ?? DateTime.now(),
        _onPointsAwarded = onPointsAwarded,
        super(
          AppointmentBookingState(
            sourceContext: sourceContext,
            offering: offering,
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
        if (offering != null) 'offering': offering.slug,
      },
    );
    loadAvailability();
  }

  final AppointmentRepository _repository;
  final AnalyticsService _analytics;
  final DateTime _now;
  final Future<void> Function(int pointsAwarded)? _onPointsAwarded;
  final Duration paymentDelay;

  Future<void> loadAvailability({int? machineId}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getAvailability(
      service: state.bookingLabel,
      offeringSlug: state.offering?.slug,
      machineId: machineId ?? state.selectedMachineId,
    );

    result.when(
      success: (window) {
        var focused = DateTime(state.focusedMonth.year, state.focusedMonth.month);
        final minMonth = DateTime(window.today.year, window.today.month);
        final maxMonth =
            DateTime(window.windowEnd.year, window.windowEnd.month);
        if (focused.isBefore(minMonth)) focused = minMonth;
        if (focused.isAfter(maxMonth)) focused = maxMonth;

        final machines = window.machines;
        int? selectedMachine =
            machineId ?? state.selectedMachineId ?? window.machineId;
        if (selectedMachine == null && machines.length == 1) {
          selectedMachine = machines.first.id;
        }

        final sessions = window.numberOfSessions > 0
            ? window.numberOfSessions
            : (state.offering?.numberOfSessions ?? 1);
        final dayGap = window.dayGap >= 0
            ? window.dayGap
            : (state.offering?.dayGap ?? 0);

        final calendarReady = selectedMachine != null ||
            machines.length <= 1 && !window.needsMachine;

        state = state.copyWith(
          availability: window,
          focusedMonth: focused,
          availableDates: calendarReady
              ? _datesForMonth(window, focused)
              : const <DateTime>{},
          machines: machines,
          selectedMachineId: selectedMachine,
          clearMachine: selectedMachine == null,
          numberOfSessions: sessions,
          dayGap: dayGap,
          clearSelectedDate: true,
          clearSelection: true,
          slots: const [],
          isLoading: false,
          clearError: true,
        );

        // Auto-reload once when a single machine is inferred.
        if (selectedMachine != null &&
            window.needsMachine &&
            window.machineId == null &&
            machineId == null) {
          loadAvailability(machineId: selectedMachine);
        }
      },
      failure: (message, _) {
        state = state.copyWith(isLoading: false, errorMessage: message);
      },
    );
  }

  Future<void> selectMachine(int machineId) async {
    state = state.copyWith(
      selectedMachineId: machineId,
      visits: const [],
      activeSessionIndex: 0,
      clearSelectedDate: true,
      clearSelection: true,
      slots: const [],
      step: AppointmentStep.date,
    );
    await loadAvailability(machineId: machineId);
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
    if (!state.calendarUnlocked) return;
    final window = state.availability;
    if (window == null) {
      await loadAvailability();
      return;
    }

    final result = resolveScheduleDatePick(
      date: date,
      window: window,
      visits: state.visits,
      numberOfSessions: state.numberOfSessions,
      activeSessionIndex: state.activeSessionIndex,
      dayGap: state.dayGap,
    );
    if (result.isError) {
      state = state.copyWith(errorMessage: result.errorMessage);
      return;
    }
    if (result.selectedDate == null) return;

    state = state.copyWith(
      selectedDate: result.selectedDate,
      slots: result.slots,
      selection: result.selection,
      clearSelection: result.selection == null,
      activeSessionIndex: result.activeSessionIndex,
      step: AppointmentStep.date,
      clearError: true,
    );
  }

  void selectSlot(TimeSlot slot) {
    final date = state.selectedDate;
    if (date == null) return;

    final result = resolveScheduleSlotPick(
      slot: slot,
      selectedDate: date,
      slots: state.slots,
      currentSelection: state.selection,
      visits: state.visits,
      numberOfSessions: state.numberOfSessions,
      requiredSlots: state.requiredSlotCount,
    );
    if (result.isError) {
      state = state.copyWith(errorMessage: result.errorMessage);
      return;
    }

    state = state.copyWith(
      selection: result.selection,
      clearSelection: result.clearSelection,
      clearSelectedDate: result.clearSelectedDate,
      visits: result.visits,
      activeSessionIndex: result.activeSessionIndex,
      clearError: true,
    );
  }

  void continueToDetails() {
    final visits = ensureVisitsFromSelection(
      visits: state.visits,
      selectedDate: state.selectedDate,
      selection: state.selection,
      numberOfSessions: state.numberOfSessions,
    );

    if (visits.length < state.numberOfSessions) {
      state = state.copyWith(
        errorMessage: state.numberOfSessions > 1
            ? 'Select a date and time for all ${state.numberOfSessions} sessions.'
            : 'Select a date and time to continue.',
      );
      return;
    }

    state = state.copyWith(
      visits: visits,
      activeSessionIndex: visits.length,
      step: AppointmentStep.details,
      clearError: true,
    );
  }

  void submitPatientDetails(PatientDetails patient) {
    state = state.copyWith(
      patient: patient,
      step: AppointmentStep.confirm,
      clearError: true,
    );
    loadQuote();
  }

  Future<void> loadQuote() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getQuote(
      service: state.bookingLabel,
      offeringSlug: state.offering?.slug,
    );
    if (result is ApiSuccess<BookingQuote>) {
      state = state.copyWith(quote: result.data, isLoading: false);
      return;
    }
    final failure = result as ApiFailure<BookingQuote>;
    state = state.copyWith(isLoading: false, errorMessage: failure.message);
  }

  void continueToPayment() {
    if (state.patient == null) return;
    final hasSchedule =
        state.visits.isNotEmpty || state.selection != null;
    if (!hasSchedule) return;
    final quote = state.quote;
    if (quote != null && quote.isFree) {
      submitPayment(skipCard: true);
      return;
    }
    final isFreeOffering = state.offering?.isFree ?? false;
    if (isFreeOffering && quote == null) {
      submitPayment(skipCard: true);
      return;
    }
    state = state.copyWith(
      step: AppointmentStep.payment,
      paymentEmail: state.patient!.email,
      clearError: true,
    );
  }

  /// After card details are valid, move to the mock OTP challenge.
  void submitCardDetails({
    required String email,
    required String cardNumber,
    required String expiry,
    required String cvc,
  }) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      paymentEmail: trimmed,
      cardNumber: cardNumber,
      cardExpiry: expiry,
      cardCvc: cvc,
      step: AppointmentStep.paymentOtp,
      clearError: true,
    );
  }

  /// Confirm payment with backend then create the pending appointment.
  Future<void> submitPayment({bool skipCard = false}) async {
    if (state.patient == null) return;
    final hasSchedule =
        state.visits.isNotEmpty || state.selection != null;
    if (!hasSchedule) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final sessionResult = await _repository.createPaymentSession(
      service: state.bookingLabel,
      offeringSlug: state.offering?.slug,
    );
    if (sessionResult is! ApiSuccess<PaymentSessionResult>) {
      final failure = sessionResult as ApiFailure<PaymentSessionResult>;
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
      return;
    }
    final session = sessionResult.data;
    state = state.copyWith(
      paymentSessionId: session.paymentSessionId,
      paymentClientSecret: session.clientSecret,
    );

    final paymentMethod = skipCard
        ? <String, dynamic>{}
        : <String, dynamic>{
            'card_number': state.cardNumber.replaceAll(RegExp(r'\s'), ''),
            'exp_month': _expiryMonth(state.cardExpiry),
            'exp_year': _expiryYear(state.cardExpiry),
            'cvc': state.cardCvc,
          };

    // Complimentary / $0 still needs confirm for session status.
    final confirmResult = await _repository.confirmPayment(
      paymentSessionId: session.paymentSessionId,
      clientSecret: session.clientSecret,
      paymentMethod: paymentMethod,
    );
    if (confirmResult is ApiFailure<void>) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: confirmResult.message,
        step: AppointmentStep.payment,
      );
      return;
    }

    await Future<void>.delayed(paymentDelay);
    await confirmBooking(fromPayment: true);
  }

  String _expiryMonth(String expiry) {
    final parts = expiry.split(RegExp(r'[/\-]'));
    if (parts.isEmpty) return '';
    return parts.first.trim().padLeft(2, '0');
  }

  String _expiryYear(String expiry) {
    final parts = expiry.split(RegExp(r'[/\-]'));
    if (parts.length < 2) return '';
    var year = parts[1].trim();
    if (year.length == 2) year = '20$year';
    return year;
  }

  void goBack() {
    switch (state.step) {
      case AppointmentStep.time:
        // Schedule is a single screen now; treat like date.
        state = state.copyWith(
          step: AppointmentStep.date,
          clearError: true,
        );
        return;
      case AppointmentStep.details:
        state = state.copyWith(step: AppointmentStep.date, clearError: true);
        return;
      case AppointmentStep.confirm:
        state = state.copyWith(step: AppointmentStep.details, clearError: true);
        return;
      case AppointmentStep.payment:
        state = state.copyWith(step: AppointmentStep.confirm, clearError: true);
        return;
      case AppointmentStep.paymentOtp:
        state = state.copyWith(step: AppointmentStep.payment, clearError: true);
        return;
      case AppointmentStep.date:
      case AppointmentStep.success:
        return;
    }
  }

  Future<void> confirmBooking({bool fromPayment = false}) async {
    final patient = state.patient;
    final visits = state.visits;
    // Commit in-progress selection if user went straight from single session.
    final effectiveVisits = visits.isNotEmpty
        ? visits
        : (state.selection != null && state.selectedDate != null
            ? [
                BookingVisit(
                  date: state.selectedDate!,
                  timeMinutes: state.selection!.startMinutes,
                  slotCount: state.selection!.slotCount,
                ),
              ]
            : const <BookingVisit>[]);
    if (patient == null || effectiveVisits.isEmpty) return;

    final slot = TimeSlot.fromAvailability(
      date: effectiveVisits.first.date,
      timeMinutes: effectiveVisits.first.timeMinutes,
    );
    final slotCount = effectiveVisits.first.slotCount;

    // Payment step owns the create call after pay succeeds.
    if (!fromPayment) {
      continueToPayment();
      return;
    }

    final paymentSessionId = state.paymentSessionId;
    if (paymentSessionId == null || paymentSessionId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Complete payment before submitting.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final request = AppointmentRequest(
      sourceContext: state.sourceContext,
      offering: state.offering,
      slot: slot,
      patient: patient,
      slotCount: slotCount,
      machineId: state.selectedMachineId,
      visits: effectiveVisits,
    );

    final result = await _repository.bookAppointment(
      request: request,
      paymentSessionId: paymentSessionId,
    );
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
        visits: effectiveVisits,
      );
      await _onPointsAwarded?.call(booking.pointsAwarded);
      return;
    }

    final failure = result as ApiFailure<AppointmentBookingResult>;
    final message = failure.message;
    final statusCode = failure.statusCode;
    state = state.copyWith(isLoading: false, errorMessage: message);

    if (statusCode == 400 || statusCode == 409 || statusCode == 402) {
      await loadAvailability(machineId: state.selectedMachineId);
      state = state.copyWith(
        step: AppointmentStep.date,
        visits: const [],
        activeSessionIndex: 0,
        clearSelectedDate: true,
        clearSelection: true,
        slots: const [],
        errorMessage: message,
      );
    }
  }

  void retryAfterError() {
    state = state.copyWith(clearError: true);
  }

  DateTime get now => _now;
}
