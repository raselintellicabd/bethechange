import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/models/slot_selection.dart';
import '../../domain/models/time_slot.dart';

class TimeSlotSelector extends StatelessWidget {
  const TimeSlotSelector({
    super.key,
    required this.slots,
    required this.selection,
    required this.onSlotSelected,
    this.requiredSlots,
  });

  final List<TimeSlot> slots;
  final SlotSelection? selection;
  final ValueChanged<TimeSlot> onSlotSelected;

  /// When set, fixed-duration mode (Django offering slot count).
  final int? requiredSlots;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const EmptyStateWidget(
        title: 'No slots available',
        message: 'Please choose another date.',
        icon: Icons.event_busy_outlined,
      );
    }

    final fixed = requiredSlots;
    final helpText = fixed == null
        ? 'Choose up to ${SlotSelection.maxSlots} consecutive open times. '
            'Tapping a later slot also selects the times in between.'
        : fixed <= 1
            ? 'Tap an open time to select this ${SlotSelection.slotMinutes}-minute session.'
            : 'This service needs $fixed consecutive '
                '${SlotSelection.slotMinutes}-minute times. '
                'Tap a start time to select the full block.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          helpText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
                height: 1.35,
              ),
        ),
        if (selection != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Selected: ${selection!.timeRangeLabel}'
            '${selection!.slotCount > 1 ? ' (${selection!.slotCount} slots)' : ''}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
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
            final selected = selection?.containsSlot(slot) ?? false;
            return _SlotTile(
              slot: slot,
              selected: selected,
              onTap: slot.isSelectable ? () => onSlotSelected(slot) : null,
            );
          },
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    final bg = selected
        ? AppColors.forest
        : enabled
            ? AppColors.card
            : AppColors.brandBgGray;
    final fg = selected
        ? Colors.white
        : enabled
            ? AppColors.ink
            : AppColors.inkMuted;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.line,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slot.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!enabled) ...[
                const SizedBox(height: 2),
                Text(
                  slot.stateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fg,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
