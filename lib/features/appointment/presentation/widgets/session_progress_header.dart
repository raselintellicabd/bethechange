import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/clinic_slots.dart';
import '../../domain/models/booking_machine.dart';

/// Shows “Session X of Y” and a list of already picked visits.
class SessionProgressHeader extends StatelessWidget {
  const SessionProgressHeader({
    super.key,
    required this.totalSessions,
    required this.activeSessionIndex,
    required this.visits,
  });

  final int totalSessions;
  final int activeSessionIndex;
  final List<BookingVisit> visits;

  @override
  Widget build(BuildContext context) {
    if (totalSessions <= 1) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final filled = visits.length;
    final current = filled >= totalSessions
        ? totalSessions
        : (filled + 1).clamp(1, totalSessions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Session $current of $totalSessions',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (visits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < visits.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Session ${i + 1}: ${_label(visits[i])}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ),
        ],
      ],
    );
  }

  String _label(BookingVisit visit) {
    final d = visit.date;
    final date =
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final start = ClinicSlots.displayLabel(visit.timeMinutes);
    if (visit.slotCount <= 1) return '$date · $start';
    final end = ClinicSlots.displayLabel(
      visit.timeMinutes + visit.slotCount * ClinicSlots.slotMinutes,
    );
    return '$date · $start – $end';
  }
}
