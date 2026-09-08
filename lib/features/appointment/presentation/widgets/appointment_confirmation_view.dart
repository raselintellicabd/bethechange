import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/patient_details.dart';
import '../../domain/models/source_context.dart';
import '../../domain/models/time_slot.dart';

class AppointmentConfirmationView extends StatelessWidget {
  const AppointmentConfirmationView({
    super.key,
    required this.sourceContext,
    required this.slot,
    required this.patient,
    required this.isLoading,
    required this.onConfirm,
    this.errorMessage,
    this.onRetry,
  });

  final SourceContext sourceContext;
  final TimeSlot slot;
  final PatientDetails patient;
  final bool isLoading;
  final VoidCallback onConfirm;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat.yMMMEd().format(slot.dateTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirm your appointment', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        _SummaryRow(label: 'For', value: sourceContext.name),
        _SummaryRow(
          label: 'Source',
          value: '${sourceContext.type.name} · ${sourceContext.id}',
        ),
        _SummaryRow(label: 'Date', value: dateLabel),
        _SummaryRow(label: 'Time', value: slot.label),
        _SummaryRow(label: 'Name', value: patient.name),
        _SummaryRow(label: 'Email', value: patient.email),
        _SummaryRow(label: 'Phone', value: patient.phone),
        if (patient.notes.isNotEmpty)
          _SummaryRow(label: 'Notes', value: patient.notes),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Dismiss error',
              variant: AppButtonVariant.text,
              onPressed: onRetry,
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Confirm booking',
          expand: true,
          isLoading: isLoading,
          onPressed: isLoading ? null : onConfirm,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
