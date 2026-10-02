import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/booking_machine.dart';

/// Dropdown to pick a station before the calendar unlocks.
class MachinePickerBar extends StatelessWidget {
  const MachinePickerBar({
    super.key,
    required this.machines,
    required this.selectedMachineId,
    required this.onSelected,
    this.enabled = true,
  });

  final List<BookingMachine> machines;
  final int? selectedMachineId;
  final ValueChanged<int> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (machines.length <= 1) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select a station',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.forest,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        InputDecorator(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: selectedMachineId != null &&
                      machines.any((m) => m.id == selectedMachineId)
                  ? selectedMachineId
                  : null,
              hint: const Text('Choose station'),
              items: [
                for (final machine in machines)
                  DropdownMenuItem(
                    value: machine.id,
                    child: Text(machine.name),
                  ),
              ],
              onChanged: !enabled
                  ? null
                  : (value) {
                      if (value != null) onSelected(value);
                    },
            ),
          ),
        ),
        if (selectedMachineId == null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Select a station to see available times.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ],
    );
  }
}
