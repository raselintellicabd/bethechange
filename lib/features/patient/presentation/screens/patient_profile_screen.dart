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

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    if (!auth.isLoggedIn || user == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppAppBar.text('Profile'),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Log in to view your profile',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontFamily: GoogleFonts.workSans().fontFamily,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your name, email, and phone are saved with your patient account.',
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Log in',
                onPressed: () {
                  context.push(
                    AppRoutes.loginPath(returnTo: AppRoutes.patientProfile),
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
      appBar: AppAppBar.text('Profile'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFD6EBEF),
              child: Text(
                user.initials,
                style: AppTextStyles.headlineMedium.copyWith(
                  fontFamily: GoogleFonts.workSans().fontFamily,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F5F6C),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              fontFamily: GoogleFonts.workSans().fontFamily,
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            user.membershipActive
                ? '${user.tierTitle} member'
                : user.tierTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          _ProfileRow(label: 'Email', value: user.email),
          const SizedBox(height: AppSpacing.md),
          _ProfileRow(
            label: 'Phone',
            value: user.phone.isEmpty ? 'Not provided' : user.phone,
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.forest,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
