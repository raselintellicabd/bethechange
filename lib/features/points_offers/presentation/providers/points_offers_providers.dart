import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../appointment/data/appointment_api_repository.dart';
import '../../../appointment/domain/booking_schedule_state.dart';
import '../../../appointment/domain/models/availability_window.dart';
import '../../../appointment/domain/models/booking_machine.dart';
import '../../../appointment/domain/models/consultation_mode.dart';
import '../../../appointment/domain/models/patient_details.dart';
import '../../../appointment/domain/models/slot_selection.dart';
import '../../../appointment/domain/models/time_slot.dart';
import '../../data/points_offers_repository.dart';
import '../../domain/models/point_offer.dart';

final pointsOffersRepositoryProvider = Provider<PointsOffersRepository>((ref) {
  return PointsOffersRepository(ref.watch(apiClientProvider));
});

final pointsOfferCatalogProvider =
    FutureProvider<PointOfferCatalog>((ref) async {
  final result = await ref.watch(pointsOffersRepositoryProvider).listOffers();
  if (result is ApiSuccess<PointOfferCatalog>) return result.data;
  throw Exception((result as ApiFailure<PointOfferCatalog>).message);
});

enum PointOfferBookStep {
  schedule,
  details,
  confirm,
  success,
}

@immutable
class PointOfferBookState {
  const PointOfferBookState({
    required this.offerId,
    this.offer,
    this.availability,
    this.focusedMonth,
    this.selectedDate,
    this.slots = const [],
    this.selection,
    this.machines = const [],
    this.selectedMachineId,
    this.visits = const [],
    this.activeSessionIndex = 0,
    this.step = PointOfferBookStep.schedule,
    this.patient,
    this.isLoading = false,
    this.errorMessage,
    this.result,
  });

  final int offerId;
  final PointOffer? offer;
  final AvailabilityWindow? availability;
  final DateTime? focusedMonth;
  final DateTime? selectedDate;
  final List<TimeSlot> slots;
  final SlotSelection? selection;
  final List<BookingMachine> machines;
  final int? selectedMachineId;
  final List<BookingVisit> visits;
  final int activeSessionIndex;
  final PointOfferBookStep step;
  final PatientDetails? patient;
  final bool isLoading;
  final String? errorMessage;
  final PointOfferClaimResult? result;

  int get numberOfSessions =>
      availability?.numberOfSessions ?? offer?.numberOfSessions ?? 1;

  int get dayGap => availability?.dayGap ?? offer?.dayGap ?? 0;

  int get requiredSlots {
    if (availability?.fixedSlotCount != null &&
        availability!.fixedSlotCount! > 0) {
      return availability!.effectivePerVisitSlots;
    }
    return (offer?.slotCount ?? 1).clamp(1, SlotSelection.maxSlots);
  }

  bool get requiresMachinePicker =>
      machines.length > 1 || (availability?.needsMachine ?? false);

  bool get calendarUnlocked =>
      !requiresMachinePicker || selectedMachineId != null;

  bool get hasSchedule =>
      visits.length >= numberOfSessions ||
      (numberOfSessions <= 1 && selectedDate != null && selection != null);

  bool get isScheduleComplete => visits.length >= numberOfSessions;

  bool isDateAvailable(DateTime day) {
    final window = availability;
    if (window == null) return false;
    return isScheduleDateAvailable(
      day: day,
      visits: visits,
      activeSessionIndex: activeSessionIndex,
      dayGap: dayGap,
      bookableDates: window.bookableDates,
    );
  }

  PointOfferBookState copyWith({
    PointOffer? offer,
    AvailabilityWindow? availability,
    DateTime? focusedMonth,
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
    PointOfferBookStep? step,
    PatientDetails? patient,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    PointOfferClaimResult? result,
  }) {
    return PointOfferBookState(
      offerId: offerId,
      offer: offer ?? this.offer,
      availability: availability ?? this.availability,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      slots: slots ?? this.slots,
      selection: clearSelection ? null : (selection ?? this.selection),
      machines: machines ?? this.machines,
      selectedMachineId:
          clearMachine ? null : (selectedMachineId ?? this.selectedMachineId),
      visits: visits ?? this.visits,
      activeSessionIndex: activeSessionIndex ?? this.activeSessionIndex,
      step: step ?? this.step,
      patient: patient ?? this.patient,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      result: result ?? this.result,
    );
  }
}

class PointOfferBookController extends StateNotifier<PointOfferBookState> {
  PointOfferBookController({
    required this.offerId,
    required PointsOffersRepository offersRepository,
    required AppointmentApiRepository appointmentRepository,
  })  : _offers = offersRepository,
        _appointments = appointmentRepository,
        super(PointOfferBookState(offerId: offerId)) {
    load();
  }

  final int offerId;
  final PointsOffersRepository _offers;
  final AppointmentApiRepository _appointments;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _offers.getOffer(offerId);
    if (result is! ApiSuccess<PointOffer>) {
      final failure = result as ApiFailure<PointOffer>;
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
      return;
    }
    final offer = result.data;
    PatientDetails? patient;
    final auth = offer.auth;
    if (auth.fullName.isNotEmpty || auth.email.isNotEmpty) {
      patient = PatientDetails(
        name: auth.fullName,
        email: auth.email,
        phone: auth.phone,
        consultationMode: ConsultationMode.inOffice,
      );
    }
    state = state.copyWith(
      offer: offer,
      patient: patient,
      isLoading: false,
    );
    await loadAvailability();
  }

  Future<void> loadAvailability({int? machineId}) async {
    final offer = state.offer;
    if (offer == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _appointments.getAvailability(
      service: offer.serviceName,
      offeringSlug: offer.serviceSlug,
      machineId: machineId ?? state.selectedMachineId,
    );
    if (result is! ApiSuccess<AvailabilityWindow>) {
      final failure = result as ApiFailure<AvailabilityWindow>;
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
      return;
    }
    final window = result.data;
    final machines = window.machines;
    int? selectedMachine =
        machineId ?? state.selectedMachineId ?? window.machineId;
    if (selectedMachine == null && machines.length == 1) {
      selectedMachine = machines.first.id;
    }
    state = state.copyWith(
      availability: window,
      focusedMonth: DateTime(window.today.year, window.today.month),
      machines: machines,
      selectedMachineId: selectedMachine,
      clearMachine: selectedMachine == null,
      isLoading: false,
      clearError: true,
    );
    if (selectedMachine != null &&
        window.needsMachine &&
        window.machineId == null &&
        machineId == null) {
      await loadAvailability(machineId: selectedMachine);
    }
  }

  Future<void> selectMachine(int machineId) async {
    state = state.copyWith(
      selectedMachineId: machineId,
      visits: const [],
      activeSessionIndex: 0,
      clearSelectedDate: true,
      clearSelection: true,
      slots: const [],
    );
    await loadAvailability(machineId: machineId);
  }

  Set<DateTime> get availableDates {
    final window = state.availability;
    if (window == null) return {};
    return {
      for (final d in window.bookableDates)
        if (state.isDateAvailable(d)) d,
      for (final v in state.visits)
        DateTime(v.date.year, v.date.month, v.date.day),
    };
  }

  void selectMonth(DateTime month) {
    state = state.copyWith(focusedMonth: DateTime(month.year, month.month));
  }

  void selectDate(DateTime date) {
    if (!state.calendarUnlocked) return;
    final window = state.availability;
    if (window == null) return;

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
      requiredSlots: state.requiredSlots,
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

  void goToDetails() {
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
      step: PointOfferBookStep.details,
      clearError: true,
    );
  }

  void saveDetails(PatientDetails details) {
    state = state.copyWith(
      patient: details,
      step: PointOfferBookStep.confirm,
      clearError: true,
    );
  }

  void goBack() {
    switch (state.step) {
      case PointOfferBookStep.details:
        state = state.copyWith(
          step: PointOfferBookStep.schedule,
          clearError: true,
        );
        return;
      case PointOfferBookStep.confirm:
        state = state.copyWith(
          step: PointOfferBookStep.details,
          clearError: true,
        );
        return;
      case PointOfferBookStep.schedule:
      case PointOfferBookStep.success:
        return;
    }
  }

  Future<bool> claim() async {
    final offer = state.offer;
    final patient = state.patient;
    var visits = state.visits;
    if (visits.isEmpty &&
        state.selection != null &&
        state.selectedDate != null) {
      visits = [
        BookingVisit(
          date: state.selectedDate!,
          timeMinutes: state.selection!.startMinutes,
          slotCount: state.selection!.slotCount,
        ),
      ];
    }
    if (offer == null || patient == null || visits.isEmpty) {
      state = state.copyWith(errorMessage: 'Missing booking details.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    final first = visits.first;
    final result = await _offers.claimOffer(
      id: offer.id,
      date: DateFormat('yyyy-MM-dd').format(first.date),
      timeMinutes: first.timeMinutes,
      slotCount: first.slotCount,
      machineId: state.selectedMachineId,
      visits: visits.length > 1
          ? visits.map((v) => v.toJson()).toList()
          : null,
      consultationMode: patient.consultationMode.apiValue,
      fullName: patient.name,
      email: patient.email,
      phone: patient.phone,
    );
    if (result is! ApiSuccess<PointOfferClaimResult>) {
      final failure = result as ApiFailure<PointOfferClaimResult>;
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
      return false;
    }
    state = state.copyWith(
      isLoading: false,
      result: result.data,
      step: PointOfferBookStep.success,
      visits: visits,
    );
    return true;
  }
}

final pointOfferBookControllerProvider = StateNotifierProvider.autoDispose
    .family<PointOfferBookController, PointOfferBookState, int>((ref, id) {
  return PointOfferBookController(
    offerId: id,
    offersRepository: ref.watch(pointsOffersRepositoryProvider),
    appointmentRepository: AppointmentApiRepository(
      ref.watch(apiClientProvider),
    ),
  );
});
