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
import '../widgets/machine_picker_bar.dart';
import '../widgets/mock_payment_success_view.dart';
import '../widgets/mock_payment_view.dart';
import '../widgets/patient_details_form.dart';
import '../widgets/session_progress_header.dart';
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
    if ((state.step == AppointmentStep.date ||
            state.step == AppointmentStep.time) &&
        state.isLoading &&
        state.availableDates.isEmpty &&
        state.selectedDate == null) {
      return const LoadingIndicator(message: 'Loading availability...');
    }

    if ((state.step == AppointmentStep.date ||
            state.step == AppointmentStep.time) &&
        state.errorMessage != null &&
        state.availableDates.isEmpty &&
        state.selectedDate == null &&
        !state.calendarUnlocked) {
      return ErrorStateWidget(
        message: state.errorMessage!,
        onRetry: controller.loadAvailability,
      );
    }

    return switch (state.step) {
      AppointmentStep.date || AppointmentStep.time => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SessionProgressHeader(
              totalSessions: state.numberOfSessions,
              activeSessionIndex: state.activeSessionIndex,
              visits: state.visits,
            ),
            if (state.machines.length > 1) ...[
              const SizedBox(height: AppSpacing.sm),
              MachinePickerBar(
                machines: state.machines,
                selectedMachineId: state.selectedMachineId,
                onSelected: controller.selectMachine,
                enabled: !state.isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text('Select a date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (!state.calendarUnlocked)
              Text(
                'Select a station to see available times.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              AppointmentCalendarView(
                focusedMonth: state.focusedMonth,
                selectedDate: state.selectedDate,
                availableDates: {
                  for (final d in state.availableDates)
                    if (state.isDateAvailable(d)) d,
                  // Keep already-booked session dates visible/tappable.
                  for (final v in state.visits)
                    DateTime(v.date.year, v.date.month, v.date.day),
                },
                sessionDates: {
                  for (final v in state.visits)
                    DateTime(v.date.year, v.date.month, v.date.day),
                },
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
              if (state.selectedDate != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Select time',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state.errorMessage != null) ...[
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                TimeSlotSelector(
                  slots: state.slots,
                  selection: state.selection,
                  requiredSlots: state.requiredSlotCount,
                  onSlotSelected: controller.selectSlot,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Continue',
                expand: true,
                onPressed: state.isScheduleComplete ||
                        (state.numberOfSessions <= 1 &&
                            state.selection != null &&
                            state.selectedDate != null)
                    ? controller.continueToDetails
                    : null,
              ),
              if (state.numberOfSessions > 1 && !state.isScheduleComplete) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Select ${state.numberOfSessions - state.visits.length} more '
                  'session${state.numberOfSessions - state.visits.length == 1 ? '' : 's'}.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
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
          quote: state.quote,
          slot: state.selectedSlot!,
          timeLabel: state.selectionTimeLabel ?? state.selectedSlot!.label,
          visits: state.visits,
          machineName: state.selectedMachineName,
          patient: state.patient!,
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
          onConfirm: controller.continueToPayment,
          onRetry: controller.retryAfterError,
        ),
      AppointmentStep.payment => MockPaymentView(
          amountLabel: state.payableLabel,
          initialEmail: state.paymentEmail.isNotEmpty
              ? state.paymentEmail
              : (state.patient?.email ?? ''),
          imageUrl: state.offering?.imageUrl,
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
          onRetry: controller.retryAfterError,
        ),
      AppointmentStep.paymentOtp => MockPaymentOtpView(
          email: state.paymentEmail,
          amountLabel: state.payableLabel,
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
          onPay: controller.submitPayment,
          onRetry: controller.retryAfterError,
        ),
      AppointmentStep.success => MockPaymentSuccessView(result: state.result!),
    };
  }
}
