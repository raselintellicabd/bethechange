import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Stripe-style mock OTP challenge (no Link branding, no external links).
class MockPaymentOtpView extends StatefulWidget {
  const MockPaymentOtpView({
    super.key,
    required this.email,
    required this.amountLabel,
    required this.isLoading,
    required this.onPay,
    this.errorMessage,
    this.onRetry,
  });

  final String email;
  final String amountLabel;
  final bool isLoading;
  final VoidCallback onPay;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<MockPaymentOtpView> createState() => _MockPaymentOtpViewState();
}

class _MockPaymentOtpViewState extends State<MockPaymentOtpView> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  String? _otpError;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    setState(() => _otpError = null);
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _submit() {
    if (_code.length != 6) {
      setState(() => _otpError = 'Enter the 6-digit code');
      return;
    }
    widget.onPay();
  }

  void _resend() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() => _otpError = null);
    _focusNodes.first.requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A new code was sent (demo).'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String get _maskedPhone {
    final digits = widget.email.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 2) {
      return '(•••) ••• ••${digits.substring(digits.length - 2)}';
    }
    return '(•••) ••• ••35';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE3E8EE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        color: Color(0xFF697386),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF0FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF635BFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE3E8EE)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  children: [
                    const Text(
                      'Verify your payment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0A2540),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 14,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Enter the code sent to '),
                          TextSpan(
                            text: _maskedPhone,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text: ' to securely complete this payment.',
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 8.0;
                        final boxWidth =
                            ((constraints.maxWidth - gap * 5) / 6)
                                .clamp(36.0, 48.0);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var i = 0; i < 6; i++)
                              SizedBox(
                                width: boxWidth,
                                height: 48,
                                child: TextField(
                                  controller: _controllers[i],
                                  focusNode: _focusNodes[i],
                                  enabled: !widget.isLoading,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0A2540),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFC9CED6),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFC9CED6),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF635BFF),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (v) => _onChanged(i, v),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: widget.isLoading ? null : _resend,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Resend code',
                        style: TextStyle(
                          color: Color(0xFF635BFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_otpError != null || widget.errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _otpError ?? widget.errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFDD464C),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.onRetry != null)
                        TextButton(
                          onPressed: widget.onRetry,
                          child: const Text('Dismiss'),
                        ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(7),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 15,
                      color: Color(0xFF9CA3AF),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Safe and secure',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D66F),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF00D66F).withValues(
                alpha: 0.6,
              ),
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Pay ${widget.amountLabel}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
