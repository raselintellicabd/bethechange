import '../clinic_slots.dart';
import 'time_slot.dart';

/// Consecutive open-slot range for booking (website `selectSlotMinute` + max 3).
class SlotSelection {
  const SlotSelection({
    required this.startMinutes,
    required this.endMinutes,
  }) : assert(endMinutes > startMinutes);

  /// Inclusive start (minutes from midnight).
  final int startMinutes;

  /// Exclusive end (minutes from midnight), e.g. 10:00–11:00 → 600–660.
  final int endMinutes;

  static const int maxSlots = 3;
  static const int slotMinutes = ClinicSlots.slotMinutes;

  int get slotCount => (endMinutes - startMinutes) ~/ slotMinutes;

  bool containsMinute(int timeMinutes) =>
      timeMinutes >= startMinutes && timeMinutes < endMinutes;

  bool containsSlot(TimeSlot slot) => containsMinute(slot.timeMinutes);

  String get timeRangeLabel {
    final start = ClinicSlots.displayLabel(startMinutes);
    final end = ClinicSlots.displayLabel(endMinutes);
    if (slotCount <= 1) return start;
    return '$start – $end';
  }

  /// Fixed-duration offering: one tap selects [requiredSlots] consecutive opens
  /// starting at the tapped minute (website `data-fixed-slot-count`).
  ///
  /// Returns the next selection, or `null` when the same block is toggled off.
  /// Throws [SlotSelectionBlockedException] when the full block is not free.
  static SlotSelection? selectFixed({
    required SlotSelection? current,
    required int clickedMinutes,
    required int requiredSlots,
    required Set<int> availableMinutes,
  }) {
    final count = requiredSlots.clamp(1, maxSlots);
    if (!availableMinutes.contains(clickedMinutes)) return current;

    final end = clickedMinutes + count * slotMinutes;
    final next = SlotSelection(
      startMinutes: clickedMinutes,
      endMinutes: end,
    );

    // Toggle off when re-tapping the same block start.
    if (current != null &&
        current.startMinutes == next.startMinutes &&
        current.endMinutes == next.endMinutes) {
      return null;
    }

    if (!rangeIsAvailable(
      availableMinutes: availableMinutes,
      startMinutes: clickedMinutes,
      endMinutes: end,
    )) {
      throw SlotSelectionBlockedException(requiredSlots: count);
    }

    return next;
  }

  /// Apply website-style selection with a hard max of [maxSlots].
  ///
  /// Returns the next selection, or `null` when the only slot is toggled off.
  /// Throws [SlotSelectionLimitException] when extending would exceed [maxSlots].
  static SlotSelection? select({
    required SlotSelection? current,
    required int clickedMinutes,
    required Set<int> availableMinutes,
  }) {
    if (!availableMinutes.contains(clickedMinutes)) return current;

    // Toggle off when clicking the only selected slot.
    if (current != null &&
        current.startMinutes == clickedMinutes &&
        current.endMinutes == clickedMinutes + slotMinutes) {
      return null;
    }

    // First click, or click before current start → new single slot.
    if (current == null || clickedMinutes < current.startMinutes) {
      return SlotSelection(
        startMinutes: clickedMinutes,
        endMinutes: clickedMinutes + slotMinutes,
      );
    }

    final end = clickedMinutes + slotMinutes;
    final count = (end - current.startMinutes) ~/ slotMinutes;
    if (count > maxSlots) {
      throw const SlotSelectionLimitException();
    }

    if (rangeIsAvailable(
      availableMinutes: availableMinutes,
      startMinutes: current.startMinutes,
      endMinutes: end,
    )) {
      return SlotSelection(
        startMinutes: current.startMinutes,
        endMinutes: end,
      );
    }

    // Gap in the middle → restart at clicked slot.
    return SlotSelection(
      startMinutes: clickedMinutes,
      endMinutes: clickedMinutes + slotMinutes,
    );
  }

  static bool rangeIsAvailable({
    required Set<int> availableMinutes,
    required int startMinutes,
    required int endMinutes,
  }) {
    for (var m = startMinutes; m < endMinutes; m += slotMinutes) {
      if (!availableMinutes.contains(m)) return false;
    }
    return true;
  }
}

class SlotSelectionLimitException implements Exception {
  const SlotSelectionLimitException();

  @override
  String toString() => 'You can select up to ${SlotSelection.maxSlots} time slots.';
}

class SlotSelectionBlockedException implements Exception {
  const SlotSelectionBlockedException({required this.requiredSlots});

  final int requiredSlots;

  @override
  String toString() {
    if (requiredSlots <= 1) {
      return 'That time is not available. Please choose another.';
    }
    return 'This service needs $requiredSlots consecutive open times. '
        'Please choose another start time.';
  }
}
