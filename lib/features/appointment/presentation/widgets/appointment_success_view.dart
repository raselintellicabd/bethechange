import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/booking_labels.dart';
import '../../domain/models/appointment_booking_result.dart';

class AppointmentSuccessView extends StatelessWidget {
  const AppointmentSuccessView({super.key, required this.result});

  final AppointmentBookingResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = result.request;
    final dateLabel = DateFormat.yMMMEd().format(request.slot.dateTime);
    final forLabel = appointmentForLabel(request.sourceContext);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: AppSpacing.xxl,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Request received', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Request #${result.confirmationId} · pending approval',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'We received your $forLabel request for $dateLabel at '
          '${request.slot.label} (${request.patient.consultationMode.label}). '
          'Our team will review and confirm. '
          'No meeting link is sent until it is approved.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Back to home',
          expand: true,
          onPressed: () => context.go(AppRoutes.home),
        ),
      ],
    );
  }
}
