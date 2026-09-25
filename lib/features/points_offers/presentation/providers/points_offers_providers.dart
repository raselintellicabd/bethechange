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
  final PointOfferBookStep step;
  final PatientDetails? patient;
  final bool isLoading;
  final String? errorMessage;
  final PointOfferClaimResult? result;

  bool get hasSchedule => selectedDate != null && selection != null;

  PointOfferBookState copyWith({
    PointOffer? offer,
    AvailabilityWindow? availability,
    DateTime? focusedMonth,
    DateTime? selectedDate,
    List<TimeSlot>? slots,
    SlotSelection? selection,
    bool clearSelection = false,
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
      selectedDate: selectedDate ?? this.selectedDate,
      slots: slots ?? this.slots,
      selection: clearSelection ? null : (selection ?? this.selection),
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

  Future<void> loadAvailability() async {
    final offer = state.offer;
    if (offer == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _appointments.getAvailability(
      service: offer.serviceName,
    );
    if (result is! ApiSuccess<AvailabilityWindow>) {
      final failure = result as ApiFailure<AvailabilityWindow>;
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
      return;
    }
    final window = result.data;
    state = state.copyWith(
      availability: window,
      focusedMonth: DateTime(window.today.year, window.today.month),
      isLoading: false,
      clearError: true,
    );
  }

  Set<DateTime> get availableDates {
    final window = state.availability;
    if (window == null) return {};
    return window.bookableDates;
  }

  void selectMonth(DateTime month) {
    state = state.copyWith(focusedMonth: DateTime(month.year, month.month));
  }

  void selectDate(DateTime date) {
    final window = state.availability;
    if (window == null) return;
    final day = DateTime(date.year, date.month, date.day);
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
    state = state.copyWith(
      selectedDate: day,
      slots: slots,
      clearSelection: true,
      clearError: true,
    );
  }

  void selectSlot(TimeSlot slot) {
    final offer = state.offer;
    if (offer == null) return;
    final availableMinutes = state.slots
        .where((s) => s.isSelectable)
        .map((s) => s.timeMinutes)
        .toSet();
    try {
      final nextSelection = SlotSelection.selectFixed(
        current: state.selection,
        clickedMinutes: slot.timeMinutes,
        requiredSlots: offer.slotCount.clamp(1, SlotSelection.maxSlots),
        availableMinutes: availableMinutes,
      );
      state = state.copyWith(
        selection: nextSelection,
        clearSelection: nextSelection == null,
        clearError: true,
      );
    } on SlotSelectionBlockedException catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void goToDetails() {
    if (!state.hasSchedule) {
      state = state.copyWith(errorMessage: 'Choose a date and time first.');
      return;
    }
    state = state.copyWith(step: PointOfferBookStep.details, clearError: true);
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
      case PointOfferBookStep.confirm:
        state = state.copyWith(
          step: PointOfferBookStep.details,
          clearError: true,
        );
      case PointOfferBookStep.schedule:
      case PointOfferBookStep.success:
        break;
    }
  }

  Future<bool> claim() async {
    final offer = state.offer;
    final patient = state.patient;
    final date = state.selectedDate;
    final selection = state.selection;
    if (offer == null || patient == null || date == null || selection == null) {
      state = state.copyWith(errorMessage: 'Missing booking details.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _offers.claimOffer(
      id: offer.id,
      date: DateFormat('yyyy-MM-dd').format(date),
      timeMinutes: selection.startMinutes,
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
    );
    return true;
  }
}

final pointOfferBookControllerProvider = StateNotifierProvider.autoDispose
    .family<PointOfferBookController, PointOfferBookState, int>((ref, offerId) {
  return PointOfferBookController(
    offerId: offerId,
    offersRepository: ref.watch(pointsOffersRepositoryProvider),
    appointmentRepository:
        AppointmentApiRepository(ref.watch(apiClientProvider)),
  );
});
