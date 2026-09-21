class BookingQuote {
  const BookingQuote({
    required this.listAmountCents,
    required this.discountCents,
    required this.payableCents,
    required this.discountPercent,
    required this.usedComplimentary,
    required this.pricingNote,
    required this.listAmountDisplay,
    required this.discountDisplay,
    required this.payableDisplay,
  });

  final int listAmountCents;
  final int discountCents;
  final int payableCents;
  final int discountPercent;
  final bool usedComplimentary;
  final String pricingNote;
  final String listAmountDisplay;
  final String discountDisplay;
  final String payableDisplay;

  bool get isFree => payableCents <= 0;

  factory BookingQuote.fromJson(Map<String, dynamic> json) {
    return BookingQuote(
      listAmountCents: (json['list_amount_cents'] as num?)?.toInt() ?? 0,
      discountCents: (json['discount_cents'] as num?)?.toInt() ?? 0,
      payableCents: (json['payable_cents'] as num?)?.toInt() ?? 0,
      discountPercent: (json['discount_percent'] as num?)?.toInt() ?? 0,
      usedComplimentary: json['used_complimentary'] == true,
      pricingNote: (json['pricing_note'] as String?)?.trim() ?? '',
      listAmountDisplay:
          (json['list_amount_display'] as String?)?.trim() ?? '',
      discountDisplay: (json['discount_display'] as String?)?.trim() ?? '',
      payableDisplay: (json['payable_display'] as String?)?.trim() ?? '',
    );
  }
}

class PaymentSessionResult {
  const PaymentSessionResult({
    required this.paymentSessionId,
    required this.clientSecret,
    required this.amountCents,
    required this.amountDisplay,
    this.provider = 'mock',
  });

  final String paymentSessionId;
  final String clientSecret;
  final int amountCents;
  final String amountDisplay;
  final String provider;

  factory PaymentSessionResult.fromJson(Map<String, dynamic> json) {
    return PaymentSessionResult(
      paymentSessionId:
          (json['payment_session_id'] as String?)?.trim() ?? '',
      clientSecret: (json['client_secret'] as String?)?.trim() ?? '',
      amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
      amountDisplay: (json['amount_display'] as String?)?.trim() ?? '',
      provider: (json['provider'] as String?)?.trim() ?? 'mock',
    );
  }
}
