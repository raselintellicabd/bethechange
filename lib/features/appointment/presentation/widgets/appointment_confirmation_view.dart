import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/booking_labels.dart';
import '../../domain/clinic_slots.dart';
import '../../domain/models/booking_machine.dart';
import '../../domain/models/booking_quote.dart';
import '../../domain/models/book_online_offering.dart';
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
    this.offering,
    this.quote,
    this.timeLabel,
    this.visits = const [],
    this.machineName,
    this.errorMessage,
    this.onRetry,
  });

  final SourceContext sourceContext;
  final BookOnlineOffering? offering;
  final BookingQuote? quote;
  final TimeSlot slot;
  final PatientDetails patient;
  final bool isLoading;
  final VoidCallback onConfirm;
  final String? timeLabel;
  final List<BookingVisit> visits;
  final String? machineName;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final multi = visits.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirm your request', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        _SummaryRow(
          label: 'For',
          value: appointmentForLabel(sourceContext, offering: offering),
        ),
        if (patient.forFamilyMember)
          const _SummaryRow(label: 'Recipient', value: 'Family member'),
        if (offering != null)
          _SummaryRow(label: 'Duration', value: offering!.durationDisplay),
        if (machineName != null && machineName!.isNotEmpty)
          _SummaryRow(label: 'Station', value: machineName!),
        if (quote != null) ...[
          _SummaryRow(label: 'List price', value: quote!.listAmountDisplay),
          if (quote!.discountCents > 0)
            _SummaryRow(label: 'Discount', value: '-${quote!.discountDisplay}'),
          _SummaryRow(label: 'Payable', value: quote!.payableDisplay),
          if (quote!.pricingNote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                quote!.pricingNote,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ] else if (offering != null)
          _SummaryRow(label: 'Price', value: offering!.priceDisplay),
        if (multi) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text('Sessions', style: theme.textTheme.labelLarge),
          ),
          for (var i = 0; i < visits.length; i++)
            _SummaryRow(
              label: 'Session ${i + 1}',
              value: _visitLabel(visits[i]),
            ),
        ] else ...[
          _SummaryRow(
            label: 'Date',
            value: DateFormat.yMMMEd().format(
              visits.isNotEmpty
                  ? DateTime(
                      visits.first.date.year,
                      visits.first.date.month,
                      visits.first.date.day,
                      visits.first.timeMinutes ~/ 60,
                      visits.first.timeMinutes % 60,
                    )
                  : slot.dateTime,
            ),
          ),
          _SummaryRow(
            label: 'Time',
            value: visits.isNotEmpty
                ? _timeRange(visits.first)
                : (timeLabel ?? slot.label),
          ),
        ],
        _SummaryRow(label: 'Mode', value: patient.consultationMode.label),
        _SummaryRow(label: 'Name', value: patient.name),
        _SummaryRow(label: 'Email', value: patient.email),
        _SummaryRow(label: 'Phone', value: patient.phone),
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
          label: 'Continue to payment',
          expand: true,
          isLoading: isLoading,
          onPressed: isLoading ? null : onConfirm,
        ),
      ],
    );
  }

  String _timeRange(BookingVisit visit) {
    final start = ClinicSlots.displayLabel(visit.timeMinutes);
    if (visit.slotCount <= 1) return start;
    final end = ClinicSlots.displayLabel(
      visit.timeMinutes + visit.slotCount * ClinicSlots.slotMinutes,
    );
    return '$start – $end';
  }

  String _visitLabel(BookingVisit visit) {
    final dateLabel = DateFormat.yMMMEd().format(
      DateTime(
        visit.date.year,
        visit.date.month,
        visit.date.day,
      ),
    );
    return '$dateLabel · ${_timeRange(visit)}';
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
