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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.6,
      ),
      itemBuilder: (context, index) {
        final slot = slots[index];
        final selected = selectedSlot?.id == slot.id;
        return _SlotTile(
          slot: slot,
          selected: selected,
          onTap: slot.isSelectable ? () => onSlotSelected(slot) : null,
        );
      },
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final TimeSlot slot;
  final bool selected;
  final VoidCallback? onTap;

  Color get _borderColor {
    if (selected) return AppColors.primary;
    return switch (slot.state) {
      'available' => const Color(0xFFCBDCE2),
      'pending' => const Color(0xFFE0C36A),
      'booked' => const Color(0xFFC5D0D5),
      'busy' => const Color(0xFFD8B4B4),
      _ => AppColors.border,
    };
  }

  Color get _backgroundColor {
    if (selected) return AppColors.primary;
    return switch (slot.state) {
      'available' => Colors.white,
      'pending' => const Color(0xFFFFF8E8),
      'booked' => const Color(0xFFEEF2F4),
      'busy' => const Color(0xFFF7ECEC),
      _ => AppColors.surfaceMuted,
    };
  }

  Color get _foregroundColor {
    if (selected) return Colors.white;
    return switch (slot.state) {
      'available' => AppColors.forest,
      'pending' => const Color(0xFF7A5B12),
      'booked' => const Color(0xFF5A6B74),
      'busy' => const Color(0xFF7A3B3B),
      _ => AppColors.inkMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: _backgroundColor,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _borderColor),
          ),
          child: Text(
            '${slot.label} · ${slot.stateLabel}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _foregroundColor.withValues(alpha: enabled ? 1 : 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.2,
                ),
          ),
        ),
      ),
    );
  }
}
