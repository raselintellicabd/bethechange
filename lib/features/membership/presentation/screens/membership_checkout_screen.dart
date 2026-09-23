import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/checkout/mock_payment_otp_view.dart';
import '../../../../core/widgets/checkout/mock_payment_view.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/membership_catalog.dart';

enum _MembershipCheckoutStep { card, otp, success }

/// Full-screen membership Join Now checkout — same card/OTP UI as appointments.
class MembershipCheckoutScreen extends ConsumerStatefulWidget {
  const MembershipCheckoutScreen({super.key, required this.plan});

  final MembershipPlan plan;

  @override
  ConsumerState<MembershipCheckoutScreen> createState() =>
      _MembershipCheckoutScreenState();
}

class _MembershipCheckoutScreenState
    extends ConsumerState<MembershipCheckoutScreen> {
  _MembershipCheckoutStep _step = _MembershipCheckoutStep.card;
  String _email = '';
  String _cardNumber = '';
  String _expiry = '';
  String _cvc = '';
  bool _isLoading = false;
  String? _errorMessage;

  String get _amountLabel {
    final price = widget.plan.priceLabel;
    if (price != null && price.isNotEmpty) return price;
    final cents = widget.plan.priceCents;
    if (cents <= 0) return 'Free';
    final dollars = cents / 100;
    final text = dollars == dollars.roundToDouble()
        ? '\$${dollars.toStringAsFixed(0)}'
        : '\$${dollars.toStringAsFixed(2)}';
    return text;
  }

  void _onCardContinue({
    required String email,
    required String cardNumber,
    required String expiry,
    required String cvc,
  }) {
    setState(() {
      _email = email;
      _cardNumber = cardNumber;
      _expiry = expiry;
      _cvc = cvc;
      _errorMessage = null;
      _step = _MembershipCheckoutStep.otp;
    });
  }

  Future<void> _onPay() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final sessionResult =
        await repo.startMembershipPayment(tier: widget.plan.tier);
    if (!mounted) return;

    if (sessionResult is ApiFailure<Map<String, dynamic>>) {
      setState(() {
        _isLoading = false;
        _errorMessage = sessionResult.message;
        _step = _MembershipCheckoutStep.card;
      });
      return;
    }

    final session = (sessionResult as ApiSuccess<Map<String, dynamic>>).data;
    final parts = _expiry.split(RegExp(r'[/\-]'));
    var year = parts.length > 1 ? parts[1].trim() : '';
    if (year.length == 2) year = '20$year';
    final month = parts.isNotEmpty ? parts[0].trim().padLeft(2, '0') : '';

    final confirm = await repo.confirmMembershipPayment(
      paymentSessionId: '${session['payment_session_id'] ?? ''}',
      clientSecret: '${session['client_secret'] ?? ''}',
      paymentMethod: {
        'card_number': _cardNumber.replaceAll(RegExp(r'\s'), ''),
        'exp_month': month,
        'exp_year': year,
        'cvc': _cvc,
      },
    );
    if (!mounted) return;

    if (confirm is ApiFailure<Map<String, dynamic>>) {
      setState(() {
        _isLoading = false;
        _errorMessage = confirm.message;
        _step = _MembershipCheckoutStep.card;
      });
      return;
    }

    await ref.read(authControllerProvider.notifier).refreshProfile();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _step = _MembershipCheckoutStep.success;
    });
  }

  void _goBack() {
    switch (_step) {
      case _MembershipCheckoutStep.card:
        context.pop();
      case _MembershipCheckoutStep.otp:
        setState(() {
          _step = _MembershipCheckoutStep.card;
          _errorMessage = null;
        });
      case _MembershipCheckoutStep.success:
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.membership);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final initialEmail =
        _email.isNotEmpty ? _email : (user?.email ?? '');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        title: Text(
          _step == _MembershipCheckoutStep.success ? '' : 'Checkout',
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : _goBack,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, AppSpacing.xxl),
        children: [
          switch (_step) {
            _MembershipCheckoutStep.card => MockPaymentView(
                amountLabel: _amountLabel,
                initialEmail: initialEmail,
                imageUrl: widget.plan.heroImageUrl,
                errorMessage: _errorMessage,
                onContinue: _onCardContinue,
                onRetry: () => setState(() => _errorMessage = null),
              ),
            _MembershipCheckoutStep.otp => MockPaymentOtpView(
                email: _email,
                amountLabel: _amountLabel,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                onPay: _onPay,
                onRetry: () => setState(() => _errorMessage = null),
              ),
            _MembershipCheckoutStep.success => _MembershipPaymentSuccess(
                planTitle: widget.plan.title,
                amountLabel: _amountLabel,
              ),
          },
        ],
      ),
    );
  }
}

class _MembershipPaymentSuccess extends StatelessWidget {
  const _MembershipPaymentSuccess({
    required this.planTitle,
    required this.amountLabel,
  });

  final String planTitle;
  final String amountLabel;

  @override
  Widget build(BuildContext context) {
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0A2540),
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Welcome to $planTitle. Your membership is now active.',
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
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.membership);
              }
            },
            child: const Text(
              'Back to memberships',
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
