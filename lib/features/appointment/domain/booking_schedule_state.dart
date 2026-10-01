import 'models/availability_window.dart';
import 'models/booking_machine.dart';
import 'models/slot_selection.dart';
import 'models/time_slot.dart';

export 'models/booking_machine.dart' show BookingVisit;

/// Mutable schedule progress shared by appointment / package / points flows.
class BookingScheduleSnapshot {
  const BookingScheduleSnapshot({
    this.availability,
    this.machines = const [],
    this.selectedMachineId,
    this.needsMachine = false,
    this.focusedMonth,
    this.selectedDate,
    this.slots = const [],
    this.selection,
    this.visits = const [],
    this.activeSessionIndex = 0,
    this.numberOfSessions = 1,
    this.dayGap = 0,
    this.requiredSlots = 1,
    this.isLoading = false,
    this.errorMessage,
  });

  final AvailabilityWindow? availability;
  final List<BookingMachine> machines;
  final int? selectedMachineId;
  final bool needsMachine;
  final DateTime? focusedMonth;
  final DateTime? selectedDate;
  final List<TimeSlot> slots;
  final SlotSelection? selection;
  final List<BookingVisit> visits;
  final int activeSessionIndex;
  final int numberOfSessions;
  final int dayGap;
  final int requiredSlots;
  final bool isLoading;
  final String? errorMessage;

  bool get requiresMachineChoice =>
      needsMachine || machines.length > 1;

  bool get hasMachineReady =>
      !requiresMachineChoice || selectedMachineId != null;

  bool get calendarUnlocked =>
      hasMachineReady && !(availability?.needsMachine ?? false);

  bool get isScheduleComplete => visits.length >= numberOfSessions;

  BookingVisit? get primaryVisit =>
      visits.isEmpty ? null : visits.first;

  BookingScheduleSnapshot copyWith({
    AvailabilityWindow? availability,
    List<BookingMachine>? machines,
    int? selectedMachineId,
    bool clearMachine = false,
    bool? needsMachine,
    DateTime? focusedMonth,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    List<TimeSlot>? slots,
    SlotSelection? selection,
    bool clearSelection = false,
    List<BookingVisit>? visits,
    int? activeSessionIndex,
    int? numberOfSessions,
    int? dayGap,
    int? requiredSlots,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BookingScheduleSnapshot(
      availability: availability ?? this.availability,
      machines: machines ?? this.machines,
      selectedMachineId:
          clearMachine ? null : (selectedMachineId ?? this.selectedMachineId),
      needsMachine: needsMachine ?? this.needsMachine,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      slots: slots ?? this.slots,
      selection: clearSelection ? null : (selection ?? this.selection),
      visits: visits ?? this.visits,
      activeSessionIndex: activeSessionIndex ?? this.activeSessionIndex,
      numberOfSessions: numberOfSessions ?? this.numberOfSessions,
      dayGap: dayGap ?? this.dayGap,
      requiredSlots: requiredSlots ?? this.requiredSlots,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Apply availability payload into schedule snapshot (auto-picks single machine).
BookingScheduleSnapshot applyAvailability(
  BookingScheduleSnapshot current,
  AvailabilityWindow window, {
  int? preferMachineId,
}) {
  final machines = window.machines;
  int? machineId = preferMachineId ?? current.selectedMachineId ?? window.machineId;
  if (machineId == null && machines.length == 1) {
    machineId = machines.first.id;
  }
  if (machineId != null &&
      machines.isNotEmpty &&
      !machines.any((m) => m.id == machineId)) {
    machineId = machines.length == 1 ? machines.first.id : null;
  }

  final today = window.today;
  return current.copyWith(
    availability: window,
    machines: machines,
    selectedMachineId: machineId,
    clearMachine: machineId == null,
    needsMachine: window.needsMachine || machines.length > 1,
    focusedMonth: DateTime(today.year, today.month),
    clearSelectedDate: true,
    slots: const [],
    clearSelection: true,
    numberOfSessions: window.numberOfSessions > 0
        ? window.numberOfSessions
        : current.numberOfSessions,
    dayGap: window.dayGap,
    requiredSlots: window.fixedSlotCount != null && window.fixedSlotCount! > 0
        ? window.effectivePerVisitSlots
        : current.requiredSlots,
    isLoading: false,
    clearError: true,
  );
}

/// Dates already taken by completed visits (and optionally other package items).
Set<DateTime> visitTakenDates(List<BookingVisit> visits) {
  return {
    for (final v in visits) DateTime(v.date.year, v.date.month, v.date.day),
  };
}

/// For fixed-gap mode, compute the expected calendar day for [sessionIndex]
/// given the first visit date. Returns null when first visit not set.
DateTime? fixedGapTargetDate({
  required List<BookingVisit> visits,
  required int sessionIndex,
  required int dayGap,
}) {
  if (visits.isEmpty || sessionIndex <= 0 || dayGap < 1) return null;
  final first = visits.first.date;
  return DateTime(first.year, first.month, first.day)
      .add(Duration(days: dayGap * sessionIndex));
}

int visitIndexForDate(List<BookingVisit> visits, DateTime day) {
  final key = DateTime(day.year, day.month, day.day);
  for (var i = 0; i < visits.length; i++) {
    final v = visits[i].date;
    if (v.year == key.year && v.month == key.month && v.day == key.day) {
      return i;
    }
  }
  return -1;
}

SlotSelection restoredSelectionForVisit(BookingVisit visit) {
  return SlotSelection(
    startMinutes: visit.timeMinutes,
    endMinutes: visit.timeMinutes + visit.slotCount * SlotSelection.slotMinutes,
  );
}

/// Shared calendar-day rules used by appointment / packages / points.
bool isScheduleDateAvailable({
  required DateTime day,
  required List<BookingVisit> visits,
  required int activeSessionIndex,
  required int dayGap,
  required Set<DateTime> bookableDates,
  Set<DateTime> blockedDates = const {},
}) {
  final normalized = DateTime(day.year, day.month, day.day);
  if (visitIndexForDate(visits, normalized) >= 0) return true;
  if (blockedDates.contains(normalized)) return false;
  if (!bookableDates.contains(normalized)) return false;
  if (dayGap >= 1 && visits.isNotEmpty && activeSessionIndex > 0) {
    final target = fixedGapTargetDate(
      visits: visits,
      sessionIndex: activeSessionIndex,
      dayGap: dayGap,
    );
    if (target != null && normalized != target) return false;
  }
  return true;
}

/// Result of tapping a calendar day in a multi-session schedule.
class ScheduleDatePickResult {
  const ScheduleDatePickResult({
    this.selectedDate,
    this.slots = const [],
    this.selection,
    this.activeSessionIndex = 0,
    this.errorMessage,
  });

  final DateTime? selectedDate;
  final List<TimeSlot> slots;
  final SlotSelection? selection;
  final int activeSessionIndex;
  final String? errorMessage;

  bool get isError => errorMessage != null;
}

ScheduleDatePickResult resolveScheduleDatePick({
  required DateTime date,
  required AvailabilityWindow window,
  required List<BookingVisit> visits,
  required int numberOfSessions,
  required int activeSessionIndex,
  required int dayGap,
  Set<DateTime> blockedDates = const {},
}) {
  final normalized = DateTime(date.year, date.month, date.day);
  final existingIndex = visitIndexForDate(visits, normalized);
  final available = isScheduleDateAvailable(
    day: normalized,
    visits: visits,
    activeSessionIndex: activeSessionIndex,
    dayGap: dayGap,
    bookableDates: window.bookableDates,
    blockedDates: blockedDates,
  );
  if (!available && existingIndex < 0) {
    if (blockedDates.contains(normalized)) {
      return const ScheduleDatePickResult(
        errorMessage:
            'Each package service must be booked on a different day.',
      );
    }
    return const ScheduleDatePickResult();
  }

  if (existingIndex < 0 &&
      visits.length >= numberOfSessions &&
      numberOfSessions > 1) {
    return ScheduleDatePickResult(
      errorMessage:
          'All $numberOfSessions sessions are selected. '
          'Tap a selected date to change its time.',
    );
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

  SlotSelection? restored;
  var activeIndex = visits.length.clamp(0, numberOfSessions - 1);
  if (existingIndex >= 0) {
    restored = restoredSelectionForVisit(visits[existingIndex]);
    activeIndex = existingIndex;
  }

  return ScheduleDatePickResult(
    selectedDate: normalized,
    slots: slots,
    selection: restored,
    activeSessionIndex: activeIndex,
  );
}

/// Result of selecting a time slot (upserts [visits] by date).
class ScheduleSlotPickResult {
  const ScheduleSlotPickResult({
    this.selection,
    this.visits = const [],
    this.activeSessionIndex = 0,
    this.clearSelectedDate = false,
    this.clearSelection = false,
    this.errorMessage,
  });

  final SlotSelection? selection;
  final List<BookingVisit> visits;
  final int activeSessionIndex;
  final bool clearSelectedDate;
  final bool clearSelection;
  final String? errorMessage;

  bool get isError => errorMessage != null;
}

ScheduleSlotPickResult resolveScheduleSlotPick({
  required TimeSlot slot,
  required DateTime selectedDate,
  required List<TimeSlot> slots,
  required SlotSelection? currentSelection,
  required List<BookingVisit> visits,
  required int numberOfSessions,
  int? requiredSlots,
}) {
  if (!slot.isSelectable) {
    return ScheduleSlotPickResult(
      selection: currentSelection,
      visits: visits,
      activeSessionIndex: visits.length.clamp(0, numberOfSessions - 1),
    );
  }

  final open = slots
      .where((s) => s.isSelectable)
      .map((s) => s.timeMinutes)
      .toSet();

  try {
    final SlotSelection? next;
    if (requiredSlots != null && requiredSlots > 0) {
      next = SlotSelection.selectFixed(
        current: currentSelection,
        clickedMinutes: slot.timeMinutes,
        requiredSlots: requiredSlots,
        availableMinutes: open,
      );
    } else {
      next = SlotSelection.select(
        current: currentSelection,
        clickedMinutes: slot.timeMinutes,
        availableMinutes: open,
      );
    }

    var nextVisits = [...visits];
    final existingIndex = visitIndexForDate(nextVisits, selectedDate);

    if (next == null) {
      if (existingIndex >= 0) {
        nextVisits.removeAt(existingIndex);
      }
      return ScheduleSlotPickResult(
        clearSelection: true,
        visits: nextVisits,
        activeSessionIndex:
            nextVisits.length.clamp(0, numberOfSessions - 1),
      );
    }

    final visit = BookingVisit(
      date: selectedDate,
      timeMinutes: next.startMinutes,
      slotCount: next.slotCount,
    );
    if (existingIndex >= 0) {
      nextVisits[existingIndex] = visit;
    } else if (nextVisits.length < numberOfSessions) {
      nextVisits = [...nextVisits, visit];
    } else {
      return ScheduleSlotPickResult(
        selection: currentSelection,
        visits: visits,
        activeSessionIndex: existingIndex >= 0
            ? existingIndex
            : visits.length.clamp(0, numberOfSessions - 1),
        errorMessage: 'All $numberOfSessions sessions are already selected.',
      );
    }

    final addedNew = existingIndex < 0;
    final needsMore = nextVisits.length < numberOfSessions;
    final nextActive = needsMore
        ? nextVisits.length
        : (existingIndex >= 0
            ? existingIndex
            : (nextVisits.length - 1).clamp(0, numberOfSessions - 1));

    return ScheduleSlotPickResult(
      selection: addedNew && needsMore ? null : next,
      clearSelection: addedNew && needsMore,
      clearSelectedDate: addedNew && needsMore,
      visits: nextVisits,
      activeSessionIndex: nextActive,
    );
  } on SlotSelectionLimitException catch (e) {
    return ScheduleSlotPickResult(
      selection: currentSelection,
      visits: visits,
      activeSessionIndex: visits.length.clamp(0, numberOfSessions - 1),
      errorMessage: e.toString(),
    );
  } on SlotSelectionBlockedException catch (e) {
    return ScheduleSlotPickResult(
      selection: currentSelection,
      visits: visits,
      activeSessionIndex: visits.length.clamp(0, numberOfSessions - 1),
      errorMessage: e.toString(),
    );
  }
}

/// Commit an in-progress single-session selection into [visits] if needed.
List<BookingVisit> ensureVisitsFromSelection({
  required List<BookingVisit> visits,
  required DateTime? selectedDate,
  required SlotSelection? selection,
  required int numberOfSessions,
}) {
  if (visits.isNotEmpty) return visits;
  if (selection == null || selectedDate == null) return visits;
  if (numberOfSessions > 1) return visits;
  return [
    BookingVisit(
      date: selectedDate,
      timeMinutes: selection.startMinutes,
      slotCount: selection.slotCount,
    ),
  ];
}
