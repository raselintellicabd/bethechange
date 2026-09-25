import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../appointment/presentation/widgets/appointment_calendar_view.dart';
import '../../../appointment/presentation/widgets/patient_details_form.dart';
import '../../../appointment/presentation/widgets/time_slot_selector.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/points_offers_providers.dart';

/// Claim a points offer — schedule + details, no card payment.
class PointOfferBookScreen extends ConsumerWidget {
  const PointOfferBookScreen({super.key, required this.offerId});

  final int offerId;

  int _stepIndex(PointOfferBookStep step) {
    return switch (step) {
      PointOfferBookStep.schedule => 0,
      PointOfferBookStep.details => 1,
      PointOfferBookStep.confirm || PointOfferBookStep.success => 2,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pointOfferBookControllerProvider(offerId));
    final controller =
        ref.read(pointOfferBookControllerProvider(offerId).notifier);
    final loggedIn = ref.watch(authControllerProvider).isLoggedIn;

    if (state.isLoading && state.offer == null) {
      return Scaffold(
        appBar: AppAppBar(
          title: const Text('Claim offer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: const LoadingIndicator(message: 'Loading offer…'),
      );
    }

    if (state.offer == null && state.errorMessage != null) {
      return Scaffold(
        appBar: AppAppBar(
          title: const Text('Claim offer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: ErrorStateWidget(
          message: state.errorMessage!,
          onRetry: controller.load,
        ),
      );
    }

    if (!loggedIn && state.step != PointOfferBookStep.success) {
      return Scaffold(
        appBar: AppAppBar(
          title: const Text('Claim offer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sign in to claim this points offer.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Log in',
                onPressed: () => context.push(
                  AppRoutes.loginPath(
                    returnTo: AppRoutes.pointsOfferBookPath(offerId),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppAppBar(
        title: Text(
          state.step == PointOfferBookStep.success
              ? 'Claimed'
              : (state.offer?.serviceName ?? 'Claim offer'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: state.step == PointOfferBookStep.schedule ||
                  state.step == PointOfferBookStep.success
              ? () => Navigator.of(context).maybePop()
              : controller.goBack,
        ),
      ),
      body: Column(
        children: [
          if (state.step != PointOfferBookStep.success)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _stepIndex(state.step)
                              ? AppColors.ochre
                              : AppColors.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: switch (state.step) {
                PointOfferBookStep.schedule =>
                  _ScheduleStep(offerId: offerId),
                PointOfferBookStep.details => _DetailsStep(offerId: offerId),
                PointOfferBookStep.confirm => _ConfirmStep(offerId: offerId),
                PointOfferBookStep.success => _SuccessStep(offerId: offerId),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleStep extends ConsumerWidget {
  const _ScheduleStep({required this.offerId});

  final int offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pointOfferBookControllerProvider(offerId));
    final controller =
        ref.read(pointOfferBookControllerProvider(offerId).notifier);
    final offer = state.offer!;
    final window = state.availability;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(offer.serviceName, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${offer.requiredPoints} points · ${offer.durationDisplay}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        if (offer.pricingNote.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(offer.pricingNote, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.md),
        if (state.isLoading || window == null)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          AppointmentCalendarView(
            focusedMonth: state.focusedMonth ??
                DateTime(window.today.year, window.today.month),
            selectedDate: state.selectedDate,
            availableDates: controller.availableDates,
            firstDay: window.today,
            lastDay: window.windowEnd,
            onMonthChanged: controller.selectMonth,
            onDateSelected: controller.selectDate,
          ),
          if (state.selectedDate != null) ...[
            const SizedBox(height: AppSpacing.md),
            TimeSlotSelector(
              slots: state.slots,
              selection: state.selection,
              requiredSlots: offer.slotCount,
              onSlotSelected: controller.selectSlot,
            ),
          ],
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            state.errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Continue',
          expand: true,
          onPressed: state.hasSchedule ? controller.goToDetails : null,
        ),
      ],
    );
  }
}

class _DetailsStep extends ConsumerWidget {
  const _DetailsStep({required this.offerId});

  final int offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pointOfferBookControllerProvider(offerId));
    final controller =
        ref.read(pointOfferBookControllerProvider(offerId).notifier);

    return PatientDetailsForm(
      initial: state.patient,
      onSubmit: controller.saveDetails,
    );
  }
}

class _ConfirmStep extends ConsumerWidget {
  const _ConfirmStep({required this.offerId});

  final int offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pointOfferBookControllerProvider(offerId));
    final controller =
        ref.read(pointOfferBookControllerProvider(offerId).notifier);
    final offer = state.offer!;
    final patient = state.patient!;
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMMMEd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirm your claim', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        _SummaryRow(label: 'Service', value: offer.serviceName),
        if (state.selectedDate != null)
          _SummaryRow(
            label: 'Date',
            value: dateFmt.format(state.selectedDate!),
          ),
        if (state.selection != null)
          _SummaryRow(
            label: 'Time',
            value: state.selection!.timeRangeLabel,
          ),
        _SummaryRow(
          label: 'Cost',
          value: '${offer.requiredPoints} points',
        ),
        _SummaryRow(label: 'Mode', value: patient.consultationMode.label),
        _SummaryRow(label: 'Name', value: patient.name),
        _SummaryRow(label: 'Email', value: patient.email),
        _SummaryRow(label: 'Phone', value: patient.phone),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            state.errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Claim with points',
          expand: true,
          isLoading: state.isLoading,
          onPressed: state.isLoading
              ? null
              : () async {
                  final ok = await controller.claim();
                  if (!ok || !context.mounted) return;
                  final balance = ref
                      .read(pointOfferBookControllerProvider(offerId))
                      .result
                      ?.pointsBalance;
                  final auth = ref.read(authControllerProvider.notifier);
                  if (balance != null) {
                    await auth.applyPointsBalance(balance);
                  } else {
                    await auth.refreshProfile();
                  }
                  ref.invalidate(pointsOfferCatalogProvider);
                },
        ),
      ],
    );
  }
}

class _SuccessStep extends ConsumerWidget {
  const _SuccessStep({required this.offerId});

  final int offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pointOfferBookControllerProvider(offerId));
    final result = state.result;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, color: AppColors.forest, size: 56),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Offer claimed',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          result?.message ??
              'Your appointment request is pending clinic confirmation.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (result != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            '${result.pointsSpent} points spent'
            '${result.pointsBalance != null ? ' · ${result.pointsBalance} remaining' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Back to home',
          expand: true,
          onPressed: () {
            ref.invalidate(pointsOfferCatalogProvider);
            context.go(AppRoutes.home);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () {
            ref.invalidate(pointsOfferCatalogProvider);
            context.go(AppRoutes.patients);
          },
          child: const Text('Back to patients'),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
