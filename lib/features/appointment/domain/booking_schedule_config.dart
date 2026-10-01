import 'models/availability_window.dart';
import 'models/book_online_offering.dart';

/// Normalized schedule rules for any booking surface.
class BookingScheduleConfig {
  const BookingScheduleConfig({
    required this.serviceLabel,
    this.offeringSlug = '',
    this.numberOfSessions = 1,
    this.dayGap = 0,
    this.requiredSlots = 1,
    this.forPackage = false,
  });

  final String serviceLabel;
  final String offeringSlug;
  final int numberOfSessions;
  final int dayGap;
  final int requiredSlots;
  final bool forPackage;

  bool get isMultiSession => numberOfSessions > 1;

  /// Fixed-gap wizard when admin set day_gap >= 1.
  bool get usesFixedGap => isMultiSession && dayGap >= 1;

  /// Flexible independent date picks when day_gap == 0 and multi-session.
  bool get usesFlexibleMulti => isMultiSession && dayGap == 0;

  bool get usesFixedSlots => requiredSlots > 1 || isMultiSession;

  factory BookingScheduleConfig.fromOffering(
    BookOnlineOffering offering, {
    String? serviceLabel,
  }) {
    return BookingScheduleConfig(
      serviceLabel: serviceLabel ?? offering.name,
      offeringSlug: offering.slug,
      numberOfSessions: offering.numberOfSessions.clamp(1, 20),
      dayGap: offering.dayGap.clamp(0, 365),
      requiredSlots: offering.requiredSlots,
    );
  }

  factory BookingScheduleConfig.general({
    required String serviceLabel,
  }) {
    return BookingScheduleConfig(
      serviceLabel: serviceLabel,
      numberOfSessions: 1,
      dayGap: 0,
      requiredSlots: 1,
    );
  }

  BookingScheduleConfig mergeAvailability(AvailabilityWindow window) {
    return BookingScheduleConfig(
      serviceLabel: serviceLabel,
      offeringSlug: offeringSlug,
      numberOfSessions: window.numberOfSessions > 0
          ? window.numberOfSessions
          : numberOfSessions,
      dayGap: window.dayGap >= 0 ? window.dayGap : dayGap,
      requiredSlots: window.fixedSlotCount != null && window.fixedSlotCount! > 0
          ? window.effectivePerVisitSlots
          : requiredSlots,
      forPackage: forPackage,
    );
  }
}
