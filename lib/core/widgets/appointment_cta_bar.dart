import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointment/domain/models/source_context.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Prominent appointment CTA that always navigates with a [SourceContext].
class AppointmentCtaBar extends StatelessWidget {
  const AppointmentCtaBar({
    super.key,
    required this.sourceContext,
    this.label = 'Request an Appointment',
    this.subtitle,
    this.icon = Icons.calendar_month_outlined,
  });

  final SourceContext sourceContext;
  final String label;
  final String? subtitle;
  final IconData icon;

  /// Builds the guarded appointment location for [sourceContext].
  static String locationFor(SourceContext sourceContext) {
    return AppRoutes.appointmentPath(sourceContext);
  }

  void _openAppointment(BuildContext context) {
    context.push(locationFor(sourceContext));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedSubtitle =
        subtitle ?? 'Requesting for: ${sourceContext.name}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(resolvedSubtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: label,
            icon: icon,
            expand: true,
            onPressed: () => _openAppointment(context),
          ),
        ],
      ),
    );
  }
}
