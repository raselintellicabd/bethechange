import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/models/book_online_offering.dart';
import '../../domain/models/source_context.dart';
import '../providers/appointment_providers.dart';
import '../widgets/appointment_calendar_view.dart';
import '../widgets/appointment_confirmation_view.dart';
import '../widgets/mock_payment_otp_view.dart';
import '../widgets/mock_payment_success_view.dart';
import '../widgets/mock_payment_view.dart';
import '../widgets/patient_details_form.dart';
import '../widgets/time_slot_selector.dart';

class AppointmentScreen extends ConsumerWidget {
  const AppointmentScreen({
    super.key,
    required this.sourceContext,
    this.offering,
  });

  final SourceContext sourceContext;
  final BookOnlineOffering? offering;

  AppointmentBookingArgs get _args => AppointmentBookingArgs(
        sourceContext: sourceContext,
        offering: offering,
      );

  int _stepIndex(AppointmentStep step) {
    return switch (step) {
      AppointmentStep.date || AppointmentStep.time => 0,
      AppointmentStep.details => 1,
      AppointmentStep.confirm ||
      AppointmentStep.payment ||
      AppointmentStep.paymentOtp ||
      AppointmentStep.success =>
        2,
    };
  }

  bool _isCheckoutChrome(AppointmentStep step) {
    return step == AppointmentStep.payment ||
        step == AppointmentStep.paymentOtp ||
        step == AppointmentStep.success;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentControllerProvider(_args));
    final controller =
        ref.read(appointmentControllerProvider(_args).notifier);
    final checkout = _isCheckoutChrome(state.step);

    return Scaffold(
      backgroundColor: checkout ? Colors.white : null,
      appBar: AppAppBar(
        title: Text(
          checkout
              ? (state.step == AppointmentStep.success ? '' : 'Checkout')
              : 'Appointment',
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: state.step == AppointmentStep.date ||
                  state.step == AppointmentStep.success
              ? () => Navigator.of(context).maybePop()
              : controller.goBack,
        ),
      ),
      body: Column(
        children: [
          if (!checkout) ...[
            StepIndicator(currentStep: _stepIndex(state.step)),
            LockedContextChip(label: state.appointmentFor),
          ],
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                checkout ? 16 : AppSpacing.md,
                0,
                checkout ? 16 : AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                _StepBody(
                  state: state,
                  controller: controller,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.state,
    required this.controller,
  });

  final AppointmentBookingState state;
  final AppointmentController controller;

  @override
  Widget build(BuildContext context) {
    if (state.step == AppointmentStep.date &&
        state.isLoading &&
        state.availableDates.isEmpty) {
      return const LoadingIndicator(message: 'Loading availability...');
    }

    if (state.step == AppointmentStep.date &&
        state.errorMessage != null &&
        state.availableDates.isEmpty) {
      return ErrorStateWidget(
        message: state.errorMessage!,
        onRetry: controller.loadAvailability,
      );
    }

    return switch (state.step) {
      AppointmentStep.date => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select a date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AppointmentCalendarView(
              focusedMonth: state.focusedMonth,
              selectedDate: state.selectedDate,
              availableDates: state.availableDates,
              firstDay: state.availability?.today ??
                  DateTime(state.focusedMonth.year, state.focusedMonth.month, 1),
              lastDay: state.availability?.windowEnd ??
                  DateTime(
                    state.focusedMonth.year,
                    state.focusedMonth.month + 1,
                    0,
                  ),
              onMonthChanged: controller.loadMonth,
              onDateSelected: controller.selectDate,
            ),
          ],
        ),
      AppointmentStep.time => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (state.isLoading)
              const LoadingIndicator(message: 'Loading time slots...')
            else ...[
              if (state.errorMessage != null) ...[
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              TimeSlotSelector(
                slots: state.slots,
                selection: state.selection,
                requiredSlots: state.requiredSlotCount,
                onSlotSelected: controller.selectSlot,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Continue',
                expand: true,
                onPressed: state.selection == null
                    ? null
                    : controller.continueToDetails,
              ),
            ],
          ],
        ),
      AppointmentStep.details => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            PatientDetailsForm(
              initial: state.patient,
              onSubmit: controller.submitPatientDetails,
            ),
          ],
        ),
      AppointmentStep.confirm => AppointmentConfirmationView(
          sourceContext: state.sourceContext,
          offering: state.offering,
          slot: state.selectedSlot!,
          timeLabel: state.selectionTimeLabel ?? state.selectedSlot!.label,
          patient: state.patient!,
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
          onConfirm: controller.continueToPayment,
          onRetry: controller.retryAfterError,
        ),
      AppointmentStep.payment => MockPaymentView(
          amountLabel: paymentAmountLabel(state.offering),
          initialEmail: state.paymentEmail.isNotEmpty
              ? state.paymentEmail
              : (state.patient?.email ?? ''),
          offering: state.offering,
          errorMessage: state.errorMessage,
          onContinue: ({required String email}) {
            controller.submitCardDetails(email: email);
          },
          onRetry: controller.retryAfterError,
        ),
      AppointmentStep.paymentOtp => MockPaymentOtpView(
          email: state.paymentEmail,
          amountLabel: paymentAmountLabel(state.offering),
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
          onPay: controller.submitPayment,
          onRetry: controller.retryAfterError,
        ),
      AppointmentStep.success => MockPaymentSuccessView(result: state.result!),
    };
  }
}
