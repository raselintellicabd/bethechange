import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class AppointmentHistoryScreen extends ConsumerWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    if (!auth.isLoggedIn || auth.user == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppAppBar.text('Appointment History'),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Log in to see appointment history',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontFamily: GoogleFonts.workSans().fontFamily,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Past and upcoming visits are available after you sign in to your patient account.',
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Log in',
                onPressed: () {
                  context.push(
                    AppRoutes.loginPath(
                      returnTo: AppRoutes.appointmentHistory,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppAppBar.text('Appointment History'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xl),
            const Icon(
              Icons.history,
              size: 48,
              color: AppColors.ochre,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No appointments yet',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                fontFamily: GoogleFonts.workSans().fontFamily,
                fontWeight: FontWeight.w700,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Past and upcoming visits will show up here once you book a service.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
