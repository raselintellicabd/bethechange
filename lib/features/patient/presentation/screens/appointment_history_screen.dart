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
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../appointment/domain/models/appointment_history_item.dart';
import '../../../appointment/presentation/providers/appointment_providers.dart';
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

    final historyAsync = ref.watch(appointmentHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppAppBar.text('Appointment History'),
      body: historyAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading…'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(appointmentHistoryProvider),
        ),
        data: (items) => _HistoryBody(items: items),
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.items});

  final List<AppointmentHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          'Your recent bookings linked to this account.',
          style: AppTextStyles.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              children: [
                const Icon(Icons.history, size: 48, color: AppColors.ochre),
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
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _HistoryCard(item: items[i]),
          ],
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final AppointmentHistoryItem item;

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
            item.whenLabel,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.forest,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.service,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.mode,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              _StatusPill(label: item.status),
              const SizedBox(width: AppSpacing.sm),
              Text(
                item.amountLabel,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.forest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7E8C8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: const Color(0xFF8A5A0B),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
