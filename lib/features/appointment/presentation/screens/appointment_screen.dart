import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/models/source_context.dart';
import '../providers/appointment_providers.dart';
import '../widgets/appointment_calendar_view.dart';
import '../widgets/appointment_confirmation_view.dart';
import '../widgets/appointment_success_view.dart';
import '../widgets/patient_details_form.dart';
import '../widgets/time_slot_selector.dart';

class AppointmentScreen extends ConsumerWidget {
  const AppointmentScreen({super.key, required this.sourceContext});

  final SourceContext sourceContext;

  int _stepIndex(AppointmentStep step) {
    return switch (step) {
      AppointmentStep.date => 0,
      AppointmentStep.time => 1,
      AppointmentStep.details ||
      AppointmentStep.confirm ||
      AppointmentStep.success =>
        2,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentControllerProvider(sourceContext));
    final controller =
        ref.read(appointmentControllerProvider(sourceContext).notifier);

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Appointment'),
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
          if (state.step != AppointmentStep.success)
            StepIndicator(currentStep: _stepIndex(state.step)),
          if (state.step != AppointmentStep.success)
            LockedContextChip(label: 'Reason: ${sourceContext.name}'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
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
        onRetry: () => controller.loadMonth(state.focusedMonth),
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
              onMonthChanged: controller.loadMonth,
              onDateSelected: controller.selectDate,
            ),
          ],
        ),
      AppointmentStep.time => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select a time',
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
                selectedSlot: state.selectedSlot,
                onSlotSelected: controller.selectSlot,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Continue',
                expand: true,
                onPressed: state.selectedSlot == null
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
          slot: state.selectedSlot!,
          patient: state.patient!,
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
          onConfirm: controller.confirmBooking,
          onRetry: controller.retryAfterError,
        ),
      AppointmentStep.success => AppointmentSuccessView(result: state.result!),
    };
  }
}
