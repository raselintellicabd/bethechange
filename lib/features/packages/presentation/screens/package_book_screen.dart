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
import '../../../../core/widgets/ui_kit.dart';
import '../../../appointment/presentation/widgets/appointment_calendar_view.dart';
import '../../../appointment/presentation/widgets/mock_payment_view.dart';
import '../../../appointment/presentation/widgets/patient_details_form.dart';
import '../../../appointment/presentation/widgets/time_slot_selector.dart';
import '../../domain/models/package_bundle.dart';
import '../providers/packages_providers.dart';

/// Multi-service package booking — same step/checkout chrome as appointments.
class PackageBookScreen extends ConsumerWidget {
  const PackageBookScreen({super.key, required this.slug});

  final String slug;

  int _stepIndex(PackageBookStep step) {
    return switch (step) {
      PackageBookStep.schedule => 0,
      PackageBookStep.details => 1,
      PackageBookStep.confirm ||
      PackageBookStep.payment ||
      PackageBookStep.paymentOtp ||
      PackageBookStep.success =>
        2,
    };
  }

  bool _isCheckout(PackageBookStep step) {
    return step == PackageBookStep.payment ||
        step == PackageBookStep.paymentOtp ||
        step == PackageBookStep.success;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(packageBookControllerProvider(slug));
    final controller = ref.read(packageBookControllerProvider(slug).notifier);
    final checkout = _isCheckout(state.step);

    if (state.isLoading && state.bundle == null) {
      return Scaffold(
        appBar: AppAppBar(
          title: const Text('Book package'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: const LoadingIndicator(message: 'Loading package…'),
      );
    }

    if (state.bundle == null && state.errorMessage != null) {
      return Scaffold(
        appBar: AppAppBar(
          title: const Text('Book package'),
          centerTitle: true,
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

    return Scaffold(
      backgroundColor: checkout ? Colors.white : null,
      appBar: AppAppBar(
        title: Text(
          checkout
              ? (state.step == PackageBookStep.success ? '' : 'Checkout')
              : 'Package',
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: state.step == PackageBookStep.schedule ||
                  state.step == PackageBookStep.success
              ? () => Navigator.of(context).maybePop()
              : controller.goBack,
        ),
      ),
      body: Column(
        children: [
          if (!checkout) ...[
            StepIndicator(currentStep: _stepIndex(state.step)),
            LockedContextChip(
              label: state.bundle?.name ?? 'Package',
              icon: Icons.card_giftcard_outlined,
            ),
          ],
          Expanded(
            child: state.step == PackageBookStep.schedule
                ? _ScheduleStep(slug: slug)
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      checkout ? 16 : AppSpacing.md,
                      0,
                      checkout ? 16 : AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    children: [
                      _StepBody(slug: slug),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StepBody extends ConsumerWidget {
  const _StepBody({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(packageBookControllerProvider(slug));
    final controller = ref.read(packageBookControllerProvider(slug).notifier);
    final amountLabel = state.bundle?.quote.payableDisplay ?? '';

    return switch (state.step) {
      PackageBookStep.schedule => const SizedBox.shrink(),
      PackageBookStep.details => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            PatientDetailsForm(
              initial: state.patient,
              onSubmit: controller.submitDetails,
            ),
          ],
        ),
      PackageBookStep.confirm => _PackageConfirmationView(slug: slug),
      PackageBookStep.payment => MockPaymentView(
          amountLabel: amountLabel,
          initialEmail: state.paymentEmail.isNotEmpty
              ? state.paymentEmail
              : (state.patient?.email ?? ''),
          errorMessage: state.errorMessage,
          onContinue: ({
            required String email,
            required String cardNumber,
            required String expiry,
            required String cvc,
          }) {
            controller.submitCardDetails(
              email: email,
              cardNumber: cardNumber,
              expiry: expiry,
              cvc: cvc,
            );
          },
        ),
      PackageBookStep.paymentOtp => MockPaymentOtpView(
          email: state.paymentEmail,
          amountLabel: amountLabel,
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
          onPay: () => controller.submitPayment(),
        ),
      PackageBookStep.success => _PackagePaymentSuccessView(
          amountLabel: amountLabel,
          packageName: state.bundle?.name ?? 'Package',
          result: state.result,
        ),
    };
  }
}

class _ScheduleStep extends ConsumerWidget {
  const _ScheduleStep({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(packageBookControllerProvider(slug));
    final controller = ref.read(packageBookControllerProvider(slug).notifier);
    final bundle = state.bundle;
    if (bundle == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                'Select appointment times',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose a different day for each service. '
                'Calendars show the next ${bundle.packageWindowDays} days.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final schedule in state.schedules) ...[
                _ServiceScheduleCard(
                  slug: slug,
                  schedule: schedule,
                  expanded: state.activeItemId == schedule.item.itemId,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppButton(
                label: 'Continue',
                expand: true,
                onPressed: state.allServicesScheduled
                    ? controller.continueToDetails
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceScheduleCard extends ConsumerWidget {
  const _ServiceScheduleCard({
    required this.slug,
    required this.schedule,
    required this.expanded,
  });

  final String slug;
  final PackageItemScheduleState schedule;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(packageBookControllerProvider(slug).notifier);
    final item = schedule.item;
    final window = schedule.availability;
    final selection = schedule.asSelection;
    final dateFmt = DateFormat('EEE, MMM d');
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selection != null ? AppColors.forest : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => controller.setActiveItem(item.itemId),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.serviceName, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          selection == null
                              ? '${item.durationDisplay} · Select date & time'
                              : '${dateFmt.format(selection.date)} · '
                                  '${schedule.selection?.timeRangeLabel ?? ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: selection == null
                                ? AppColors.inkMuted
                                : AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selection != null
                        ? Icons.check_circle
                        : (expanded
                            ? Icons.expand_less
                            : Icons.expand_more),
                    color: selection != null
                        ? AppColors.forest
                        : AppColors.inkMuted,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: schedule.isLoading || window == null
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppointmentCalendarView(
                          focusedMonth: schedule.focusedMonth ??
                              DateTime(window.today.year, window.today.month),
                          selectedDate: schedule.selectedDate,
                          availableDates:
                              controller.availableDatesFor(item.itemId),
                          firstDay: window.today,
                          lastDay: window.windowEnd,
                          onMonthChanged: (m) =>
                              controller.selectMonth(item.itemId, m),
                          onDateSelected: (d) =>
                              controller.selectDate(item.itemId, d),
                        ),
                        if (schedule.selectedDate != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          TimeSlotSelector(
                            slots: schedule.slots,
                            selection: schedule.selection,
                            requiredSlots: item.slotCount,
                            onSlotSelected: (slot) =>
                                controller.selectSlot(item.itemId, slot),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Matches [AppointmentConfirmationView] layout for packages.
class _PackageConfirmationView extends ConsumerWidget {
  const _PackageConfirmationView({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(packageBookControllerProvider(slug));
    final controller = ref.read(packageBookControllerProvider(slug).notifier);
    final bundle = state.bundle!;
    final patient = state.patient!;
    final quote = bundle.quote;
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMMMEd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirm your request', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        _SummaryRow(label: 'Package', value: bundle.name),
        for (final schedule in state.schedules) ...[
          if (schedule.asSelection != null)
            _SummaryRow(
              label: 'Service',
              value: schedule.item.serviceName,
            ),
          if (schedule.asSelection != null)
            _SummaryRow(
              label: 'Date',
              value: dateFmt.format(schedule.asSelection!.date),
            ),
          if (schedule.selection != null)
            _SummaryRow(
              label: 'Time',
              value: schedule.selection!.timeRangeLabel,
            ),
        ],
        _SummaryRow(label: 'List price', value: quote.listAmountDisplay),
        if (quote.discountCents > 0)
          _SummaryRow(label: 'Discount', value: '-${quote.discountDisplay}'),
        _SummaryRow(label: 'Payable', value: quote.payableDisplay),
        if (quote.pricingNote.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(quote.pricingNote, style: theme.textTheme.bodySmall),
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
          label: quote.isFree ? 'Confirm booking' : 'Continue to payment',
          expand: true,
          isLoading: state.isLoading,
          onPressed: state.isLoading ? null : controller.continueToPayment,
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

/// Same Stripe-style success chrome as appointment booking.
class _PackagePaymentSuccessView extends StatelessWidget {
  const _PackagePaymentSuccessView({
    required this.amountLabel,
    required this.packageName,
    required this.result,
  });

  final String amountLabel;
  final String packageName;
  final PackageBookingResult? result;

  @override
  Widget build(BuildContext context) {
    final purchaseId = result?.purchaseId;
    final descriptor =
        packageName.trim().isNotEmpty ? packageName : 'Be The Change';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF34D399), width: 3),
            ),
            child: const Icon(
              Icons.check,
              size: 40,
              color: Color(0xFF34D399),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment successful',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            amountLabel,
            style: const TextStyle(
              color: Color(0xFF0A2540),
              fontSize: 40,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'The payment will appear on your statement as “$descriptor”.\n'
              '${purchaseId != null && purchaseId > 0 ? 'Request #$purchaseId is pending approval.' : 'Your appointment requests are pending approval.'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 28),
          TextButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text(
              'Back to home',
              style: TextStyle(
                color: Color(0xFF635BFF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
