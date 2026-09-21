import 'package:flutter/foundation.dart';
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
import '../../domain/models/book_online_catalog.dart';
import '../../domain/models/book_online_offering.dart';
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

  bool get hasFixedDuration => offering != null;

  int? get requiredSlotCount => offering?.requiredSlots;

  String get bookingLabel =>
      bookingServiceLabel(sourceContext, offering: offering);

  String get appointmentFor =>
      appointmentForLabel(sourceContext, offering: offering);

  String get payableLabel =>
      quote?.payableDisplay ?? offering?.priceDisplay ?? '—';

  /// First slot of the selected range (for booking payload).
  TimeSlot? get selectedSlot {
    final range = selection;
    if (range == null) return null;
    for (final slot in slots) {
      if (slot.timeMinutes == range.startMinutes) return slot;
    }
    return null;
  }

  int get selectedSlotCount => selection?.slotCount ?? 0;

  String? get selectionTimeLabel => selection?.timeRangeLabel;

  bool isDateAvailable(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return availableDates.contains(normalized);
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
  })  : _analytics = analytics ?? const LoggingAnalyticsService(),
        _now = now ?? DateTime.now(),
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
  final Duration paymentDelay;

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
      clearSelection: true,
      slots: slots,
      step: AppointmentStep.time,
      clearError: true,
    );
  }

  void selectSlot(TimeSlot slot) {
    if (!slot.isSelectable) return;

    final open = state.slots
        .where((s) => s.isSelectable)
        .map((s) => s.timeMinutes)
        .toSet();

    try {
      final SlotSelection? next;
      final required = state.requiredSlotCount;
      if (required != null) {
        next = SlotSelection.selectFixed(
          current: state.selection,
          clickedMinutes: slot.timeMinutes,
          requiredSlots: required,
          availableMinutes: open,
        );
      } else {
        next = SlotSelection.select(
          current: state.selection,
          clickedMinutes: slot.timeMinutes,
          availableMinutes: open,
        );
      }
      state = state.copyWith(
        selection: next,
        clearSelection: next == null,
        clearError: true,
      );
    } on SlotSelectionLimitException catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } on SlotSelectionBlockedException catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void continueToDetails() {
    if (state.selection == null || state.selectedSlot == null) return;
    state = state.copyWith(step: AppointmentStep.details, clearError: true);
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
    if (state.selection == null ||
        state.selectedSlot == null ||
        state.patient == null) {
      return;
    }
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
    if (state.selection == null ||
        state.selectedSlot == null ||
        state.patient == null) {
      return;
    }

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
        state = state.copyWith(
          step: AppointmentStep.date,
          clearSelection: true,
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
    final slot = state.selectedSlot;
    final selection = state.selection;
    final patient = state.patient;
    if (slot == null || selection == null || patient == null) return;

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
      slotCount: selection.slotCount,
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
      );
      return;
    }

    final failure = result as ApiFailure<AppointmentBookingResult>;
    final message = failure.message;
    final statusCode = failure.statusCode;
    state = state.copyWith(isLoading: false, errorMessage: message);

    if (statusCode == 400 || statusCode == 409 || statusCode == 402) {
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
          clearSelection: true,
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
