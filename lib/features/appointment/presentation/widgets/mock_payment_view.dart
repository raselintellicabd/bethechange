import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/book_online_offering.dart';

/// Stripe-style mock card checkout (no address, no real charge).
class MockPaymentView extends StatefulWidget {
  const MockPaymentView({
    super.key,
    required this.amountLabel,
    required this.initialEmail,
    required this.onContinue,
    this.offering,
    this.errorMessage,
    this.onRetry,
  });

  final String amountLabel;
  final String initialEmail;
  final BookOnlineOffering? offering;
  final void Function({
    required String email,
    required String cardNumber,
    required String expiry,
    required String cvc,
  }) onContinue;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<MockPaymentView> createState() => _MockPaymentViewState();
}

class _MockPaymentViewState extends State<MockPaymentView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();

  static const _border = Color(0xFFC9CED6);
  static const _label = Color(0xFF697386);
  static const _payBlue = Color(0xFF0A2540);
  static const _fieldRadius = 6.0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onContinue(
      email: _emailController.text.trim(),
      cardNumber: _numberController.text.trim(),
      expiry: _expiryController.text.trim(),
      cvc: _cvcController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.offering?.imageUrl ?? '';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                _ProductThumb(imageUrl: imageUrl),
                const SizedBox(height: 20),
                const Text(
                  'Pay',
                  style: TextStyle(
                    color: _label,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.amountLabel,
                  style: const TextStyle(
                    color: _payBlue,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const _FieldLabel('Email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            style: const TextStyle(fontSize: 16, color: _payBlue, height: 1.25),
            decoration: _emailDecoration(hint: 'jane.diaz@example.com'),
            validator: (value) {
              final email = (value ?? '').trim();
              if (email.isEmpty || !email.contains('@')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Card information'),
          const SizedBox(height: 8),
          _CardInfoBox(
            numberController: _numberController,
            expiryController: _expiryController,
            cvcController: _cvcController,
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.errorMessage!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
            if (widget.onRetry != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: widget.onRetry,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Dismiss'),
                ),
              ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF635BFF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Demo checkout — no real charge.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _label,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  InputDecoration _emailDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA3ACB9), fontSize: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: Color(0xFF635BFF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF697386),
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 64,
      height: 64,
      color: const Color(0xFFE8F0FE),
      child: const Icon(Icons.spa_outlined, color: Color(0xFF635BFF), size: 28),
    );

    Widget image = placeholder;
    if (imageUrl.startsWith('http')) {
      image = CachedNetworkImage(
        imageUrl: imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      );
    }

    // Reserve space under the image for the overlapping badge.
    return SizedBox(
      width: 64,
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 64, height: 64, child: image),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE3E8EE)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Text(
                '1 item',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A2540),
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardInfoBox extends StatelessWidget {
  const _CardInfoBox({
    required this.numberController,
    required this.expiryController,
    required this.cvcController,
  });

  final TextEditingController numberController;
  final TextEditingController expiryController;
  final TextEditingController cvcController;

  static const _border = Color(0xFFC9CED6);

  static InputDecoration _bare({
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA3ACB9), fontSize: 16),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.zero,
      errorStyle: const TextStyle(fontSize: 11, height: 1),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 22,
        minHeight: 22,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: numberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        _CardNumberFormatter(),
                      ],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF0A2540),
                        height: 1.25,
                      ),
                      decoration: _bare(hint: '1234 1234 1234 1234'),
                      validator: (value) {
                        final digits = (value ?? '').replaceAll(' ', '');
                        if (digits.length < 13) {
                          return 'Enter a valid card number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _BrandChips(),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _border),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                      child: TextFormField(
                        controller: expiryController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryFormatter(),
                        ],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF0A2540),
                          height: 1.25,
                        ),
                        decoration: _bare(hint: 'MM / YY'),
                        validator: (value) {
                          final raw =
                              (value ?? '').replaceAll(RegExp(r'\D'), '');
                          if (raw.length != 4) return 'Invalid';
                          final month = int.tryParse(raw.substring(0, 2)) ?? 0;
                          if (month < 1 || month > 12) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: _border,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                      child: TextFormField(
                        controller: cvcController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF0A2540),
                          height: 1.25,
                        ),
                        decoration: _bare(
                          hint: 'CVC',
                          suffix: const Icon(
                            Icons.credit_card,
                            size: 18,
                            color: Color(0xFFA3ACB9),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().length < 3) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandChips extends StatelessWidget {
  const _BrandChips();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BrandPill(label: 'VISA', color: Color(0xFF1A1F71)),
        SizedBox(width: 3),
        _BrandPill(label: 'MC', color: Color(0xFFEB001B)),
        SizedBox(width: 3),
        _BrandPill(label: 'AMEX', color: Color(0xFF2E77BC)),
      ],
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFFE3E8EE)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          height: 1.1,
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    var text = digits;
    if (digits.length >= 3) {
      text = '${digits.substring(0, 2)} / ${digits.substring(2)}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String paymentAmountLabel(BookOnlineOffering? offering) {
  if (offering == null) return 'Free';
  return offering.priceDisplay;
}
