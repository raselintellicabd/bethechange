import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointment/domain/models/source_context.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Prominent appointment CTA that always navigates with a [SourceContext].
class AppointmentCtaBar extends StatelessWidget {
  const AppointmentCtaBar({
    super.key,
    required this.sourceContext,
    this.label = 'Request an appointment',
    this.subtitle,
    this.icon = Icons.calendar_month_outlined,
  });

  final SourceContext sourceContext;
  final String label;
  final String? subtitle;
  final IconData icon;

  static String locationFor(SourceContext sourceContext) {
    return AppRoutes.appointmentPath(sourceContext);
  }

  void _openAppointment(BuildContext context) {
    context.push(locationFor(sourceContext));
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSubtitle =
        subtitle ?? 'Reason: ${sourceContext.name}';

    return Semantics(
      button: true,
      label: '$label for ${sourceContext.name}',
      child: Material(
        color: AppColors.ochre,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: () => _openAppointment(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        resolvedSubtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
