import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../appointment/data/appointment_api_repository.dart';
import '../../../appointment/domain/models/availability_window.dart';
import '../../../appointment/domain/models/consultation_mode.dart';
import '../../../appointment/domain/models/patient_details.dart';
import '../../../appointment/domain/models/slot_selection.dart';
import '../../../appointment/domain/models/time_slot.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/packages_repository.dart';
import '../../domain/models/package_bundle.dart';
import '../../../points_offers/presentation/providers/points_offers_providers.dart';

final packagesRepositoryProvider = Provider<PackagesRepository>((ref) {
  return PackagesRepository(ref.watch(apiClientProvider));
});

final packageCatalogProvider = FutureProvider<PackageCatalog>((ref) async {
  final result = await ref.watch(packagesRepositoryProvider).listPackages();
  if (result is ApiSuccess<PackageCatalog>) return result.data;
  throw Exception((result as ApiFailure<PackageCatalog>).message);
});

enum PackageBookStep {
  schedule,
  details,
  confirm,
  payment,
  paymentOtp,
  success,
}

@immutable
class PackageItemScheduleState {
  const PackageItemScheduleState({
    required this.item,
    this.availability,
    this.focusedMonth,
    this.selectedDate,
    this.slots = const [],
    this.selection,
    this.isLoading = false,
    this.errorMessage,
  });

  final PackageItem item;
  final AvailabilityWindow? availability;
  final DateTime? focusedMonth;
  final DateTime? selectedDate;
  final List<TimeSlot> slots;
  final SlotSelection? selection;
  final bool isLoading;
  final String? errorMessage;

  PackageSelection? get asSelection {
    final date = selectedDate;
    final sel = selection;
    if (date == null || sel == null) return null;
    return PackageSelection(
      itemId: item.itemId,
      date: date,
      timeMinutes: sel.startMinutes,
    );
  }

  PackageItemScheduleState copyWith({
    AvailabilityWindow? availability,
    DateTime? focusedMonth,
    DateTime? selectedDate,
    List<TimeSlot>? slots,
    SlotSelection? selection,
    bool clearSelection = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PackageItemScheduleState(
      item: item,
      availability: availability ?? this.availability,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      slots: slots ?? this.slots,
      selection: clearSelection ? null : (selection ?? this.selection),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PackageBookState {
  const PackageBookState({
    required this.slug,
    this.bundle,
    this.schedules = const [],
    this.activeItemId,
    this.step = PackageBookStep.schedule,
    this.patient,
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

  final String slug;
  final PackageBundle? bundle;
  final List<PackageItemScheduleState> schedules;
  final int? activeItemId;
  final PackageBookStep step;
  final PatientDetails? patient;
  final String paymentEmail;
  final String cardNumber;
  final String cardExpiry;
  final String cardCvc;
  final String? paymentSessionId;
  final String? paymentClientSecret;
  final bool isLoading;
  final String? errorMessage;
  final PackageBookingResult? result;

  bool get allServicesScheduled =>
      schedules.isNotEmpty &&
      schedules.every((s) => s.asSelection != null);

  Set<DateTime> takenDatesExcept(int itemId) {
    final dates = <DateTime>{};
    for (final s in schedules) {
      if (s.item.itemId == itemId) continue;
      final date = s.selectedDate;
      if (date != null) {
        dates.add(DateTime(date.year, date.month, date.day));
      }
    }
    return dates;
  }

  PackageBookState copyWith({
    PackageBundle? bundle,
    List<PackageItemScheduleState>? schedules,
    int? activeItemId,
    bool clearActiveItem = false,
    PackageBookStep? step,
    PatientDetails? patient,
    String? paymentEmail,
    String? cardNumber,
    String? cardExpiry,
    String? cardCvc,
    String? paymentSessionId,
    String? paymentClientSecret,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    PackageBookingResult? result,
  }) {
    return PackageBookState(
      slug: slug,
      bundle: bundle ?? this.bundle,
      schedules: schedules ?? this.schedules,
      activeItemId:
          clearActiveItem ? null : (activeItemId ?? this.activeItemId),
      step: step ?? this.step,
      patient: patient ?? this.patient,
      paymentEmail: paymentEmail ?? this.paymentEmail,
      cardNumber: cardNumber ?? this.cardNumber,
      cardExpiry: cardExpiry ?? this.cardExpiry,
      cardCvc: cardCvc ?? this.cardCvc,
      paymentSessionId: paymentSessionId ?? this.paymentSessionId,
      paymentClientSecret:
          paymentClientSecret ?? this.paymentClientSecret,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      result: result ?? this.result,
    );
  }
}

class PackageBookController extends StateNotifier<PackageBookState> {
  PackageBookController({
    required this.slug,
    required PackagesRepository packagesRepository,
    required AppointmentApiRepository appointmentRepository,
    Future<void> Function(int pointsAwarded)? onPointsAwarded,
  })  : _packages = packagesRepository,
        _appointments = appointmentRepository,
        _onPointsAwarded = onPointsAwarded,
        super(PackageBookState(slug: slug)) {
    load();
  }

  final String slug;
  final PackagesRepository _packages;
  final AppointmentApiRepository _appointments;
  final Future<void> Function(int pointsAwarded)? _onPointsAwarded;

  static const paymentDelay = Duration(milliseconds: 400);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _packages.getPackage(slug);
    if (result is! ApiSuccess<PackageBundle>) {
      final failure = result as ApiFailure<PackageBundle>;
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
      return;
    }
    final bundle = result.data;
    final schedules = bundle.items
        .map((item) => PackageItemScheduleState(item: item))
        .toList();
    PatientDetails? patient;
    final auth = bundle.auth;
    if (auth.fullName.isNotEmpty || auth.email.isNotEmpty) {
      patient = PatientDetails(
        name: auth.fullName,
        email: auth.email,
        phone: auth.phone,
        consultationMode: ConsultationMode.inOffice,
      );
    }
    state = state.copyWith(
      bundle: bundle,
      schedules: schedules,
      activeItemId: schedules.isNotEmpty ? schedules.first.item.itemId : null,
      patient: patient,
      isLoading: false,
    );
    for (final item in bundle.items) {
      await loadAvailability(item.itemId);
    }
  }

  Future<void> loadAvailability(int itemId) async {
    final index = state.schedules.indexWhere((s) => s.item.itemId == itemId);
    if (index < 0) return;
    final current = state.schedules[index];
    final schedules = [...state.schedules];
    schedules[index] = current.copyWith(isLoading: true, clearError: true);
    state = state.copyWith(schedules: schedules);

    final result = await _appointments.getAvailability(
      service: current.item.serviceName,
      forPackage: true,
    );
    if (result is! ApiSuccess<AvailabilityWindow>) {
      final failure = result as ApiFailure<AvailabilityWindow>;
      final next = [...state.schedules];
      next[index] = state.schedules[index].copyWith(
        isLoading: false,
        errorMessage: failure.message,
      );
      state = state.copyWith(schedules: next);
      return;
    }

    final window = result.data;
    final next = [...state.schedules];
    next[index] = state.schedules[index].copyWith(
      availability: window,
      focusedMonth: DateTime(window.today.year, window.today.month),
      isLoading: false,
      clearError: true,
    );
    state = state.copyWith(schedules: next);
  }

  void setActiveItem(int itemId) {
    state = state.copyWith(activeItemId: itemId, clearError: true);
  }

  void selectMonth(int itemId, DateTime month) {
    final index = state.schedules.indexWhere((s) => s.item.itemId == itemId);
    if (index < 0) return;
    final next = [...state.schedules];
    next[index] = state.schedules[index].copyWith(
      focusedMonth: DateTime(month.year, month.month),
    );
    state = state.copyWith(schedules: next);
  }

  void selectDate(int itemId, DateTime date) {
    final index = state.schedules.indexWhere((s) => s.item.itemId == itemId);
    if (index < 0) return;
    final schedule = state.schedules[index];
    final window = schedule.availability;
    if (window == null) return;

    final day = DateTime(date.year, date.month, date.day);
    if (state.takenDatesExcept(itemId).contains(day)) {
      state = state.copyWith(
        errorMessage:
            'Each package service must be booked on a different day.',
      );
      return;
    }

    final slots = window
        .slotsOn(day)
        .map(
          (s) => TimeSlot.fromAvailability(
            date: day,
            timeMinutes: s.timeMinutes,
            state: s.state,
          ),
        )
        .toList();

    final next = [...state.schedules];
    next[index] = schedule.copyWith(
      selectedDate: day,
      slots: slots,
      clearSelection: true,
      clearError: true,
    );
    state = state.copyWith(schedules: next, clearError: true);
  }

  void selectSlot(int itemId, TimeSlot slot) {
    final index = state.schedules.indexWhere((s) => s.item.itemId == itemId);
    if (index < 0) return;
    final schedule = state.schedules[index];
    final availableMinutes = schedule.slots
        .where((s) => s.isSelectable)
        .map((s) => s.timeMinutes)
        .toSet();

    try {
      final nextSelection = SlotSelection.selectFixed(
        current: schedule.selection,
        clickedMinutes: slot.timeMinutes,
        requiredSlots: schedule.item.slotCount.clamp(1, SlotSelection.maxSlots),
        availableMinutes: availableMinutes,
      );
      final next = [...state.schedules];
      next[index] = schedule.copyWith(
        selection: nextSelection,
        clearSelection: nextSelection == null,
        clearError: true,
      );
      state = state.copyWith(schedules: next, clearError: true);
    } on SlotSelectionBlockedException catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Set<DateTime> availableDatesFor(int itemId) {
    final index = state.schedules.indexWhere((s) => s.item.itemId == itemId);
    if (index < 0) return {};
    final window = state.schedules[index].availability;
    if (window == null) return {};
    final taken = state.takenDatesExcept(itemId);
    return window.bookableDates.difference(taken);
  }

  void continueToDetails() {
    if (!state.allServicesScheduled) {
      state = state.copyWith(
        errorMessage:
            'Choose an appointment time for every service in this package.',
      );
      return;
    }
    state = state.copyWith(
      step: PackageBookStep.details,
      clearError: true,
    );
  }

  void submitDetails(PatientDetails patient) {
    state = state.copyWith(
      patient: patient,
      step: PackageBookStep.confirm,
      clearError: true,
    );
  }

  void continueToPayment() {
    final quote = state.bundle?.quote;
    if (quote != null && quote.isFree) {
      submitPayment(skipCard: true);
      return;
    }
    state = state.copyWith(
      step: PackageBookStep.payment,
      paymentEmail: state.patient?.email ?? '',
      clearError: true,
    );
  }

  void submitCardDetails({
    required String email,
    required String cardNumber,
    required String expiry,
    required String cvc,
  }) {
    state = state.copyWith(
      paymentEmail: email.trim(),
      cardNumber: cardNumber,
      cardExpiry: expiry,
      cardCvc: cvc,
      step: PackageBookStep.paymentOtp,
      clearError: true,
    );
  }

  Future<void> submitPayment({bool skipCard = false}) async {
    if (!state.allServicesScheduled || state.patient == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final sessionResult = await _packages.createPaymentSession(slug);
    if (sessionResult is! ApiSuccess<PackagePaymentSession>) {
      final failure = sessionResult as ApiFailure<PackagePaymentSession>;
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        step: PackageBookStep.payment,
      );
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

    final confirmResult = await _appointments.confirmPayment(
      paymentSessionId: session.paymentSessionId,
      clientSecret: session.clientSecret,
      paymentMethod: paymentMethod,
    );
    if (confirmResult is ApiFailure<void>) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: confirmResult.message,
        step: PackageBookStep.payment,
      );
      return;
    }

    await Future<void>.delayed(paymentDelay);

    final selections = state.schedules
        .map((s) => s.asSelection)
        .whereType<PackageSelection>()
        .toList();
    final patient = state.patient!;
    final bookResult = await _packages.bookPackage(
      slug: slug,
      paymentSessionId: session.paymentSessionId,
      fullName: patient.name,
      email: patient.email,
      phone: patient.phone,
      consultationMode: patient.consultationMode.apiValue,
      selections: selections,
    );

    if (bookResult is! ApiSuccess<PackageBookingResult>) {
      final failure = bookResult as ApiFailure<PackageBookingResult>;
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        step: PackageBookStep.schedule,
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      result: bookResult.data,
      step: PackageBookStep.success,
      clearError: true,
    );
    await _onPointsAwarded?.call(bookResult.data.pointsAwarded);
  }

  void goBack() {
    switch (state.step) {
      case PackageBookStep.details:
        state = state.copyWith(step: PackageBookStep.schedule);
      case PackageBookStep.confirm:
        state = state.copyWith(step: PackageBookStep.details);
      case PackageBookStep.payment:
        state = state.copyWith(step: PackageBookStep.confirm);
      case PackageBookStep.paymentOtp:
        state = state.copyWith(step: PackageBookStep.payment);
      case PackageBookStep.schedule:
      case PackageBookStep.success:
        break;
    }
  }

  String selectionSummary() {
    final lines = <String>[];
    final fmt = DateFormat('EEE, MMM d');
    for (final s in state.schedules) {
      final sel = s.asSelection;
      if (sel == null) continue;
      final time = s.selection?.timeRangeLabel ?? '';
      lines.add('${s.item.serviceName}: ${fmt.format(sel.date)} · $time');
    }
    return lines.join('\n');
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
}

final packageBookControllerProvider = StateNotifierProvider.autoDispose
    .family<PackageBookController, PackageBookState, String>((ref, slug) {
  return PackageBookController(
    slug: slug,
    packagesRepository: ref.watch(packagesRepositoryProvider),
    appointmentRepository:
        AppointmentApiRepository(ref.watch(apiClientProvider)),
    onPointsAwarded: (awarded) async {
      if (awarded > 0) {
        await ref.read(authControllerProvider.notifier).addPoints(awarded);
      } else {
        await ref.read(authControllerProvider.notifier).refreshProfile();
      }
      ref.invalidate(pointsOfferCatalogProvider);
    },
  );
});
