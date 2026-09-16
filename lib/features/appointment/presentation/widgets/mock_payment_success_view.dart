import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/appointment_booking_result.dart';
import 'mock_payment_view.dart';

/// Stripe-style payment success (appointment create already completed).
class MockPaymentSuccessView extends StatelessWidget {
  const MockPaymentSuccessView({super.key, required this.result});

  final AppointmentBookingResult result;

  @override
  Widget build(BuildContext context) {
    final amount = paymentAmountLabel(result.request.offering);
    final descriptor = result.request.offering?.name.trim().isNotEmpty == true
        ? result.request.offering!.name
        : 'Be The Change';

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
            amount,
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
              'Request #${result.confirmationId} is pending approval.',
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
