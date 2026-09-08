import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/models/time_slot.dart';

class TimeSlotSelector extends StatelessWidget {
  const TimeSlotSelector({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final ValueChanged<TimeSlot> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const EmptyStateWidget(
        title: 'No slots available',
        message: 'Please choose another date.',
        icon: Icons.event_busy_outlined,
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final slot in slots)
          ChoiceChip(
            label: Text(slot.label),
            selected: selectedSlot?.id == slot.id,
            selectedColor: AppColors.primaryLight.withValues(alpha: 0.35),
            onSelected: (_) => onSlotSelected(slot),
          ),
      ],
    );
  }
}
