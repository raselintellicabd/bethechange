/// Package/bundle catalog models from `GET /api/v1/packages/`.
class PackageQuote {
  const PackageQuote({
    required this.listAmountCents,
    required this.discountCents,
    required this.payableCents,
    required this.discountPercent,
    required this.pricingNote,
    required this.listAmountDisplay,
    required this.discountDisplay,
    required this.payableDisplay,
    this.tier = 0,
    this.pricingMode = 'percent',
  });

  final int listAmountCents;
  final int discountCents;
  final int payableCents;
  final int discountPercent;
  final String pricingNote;
  final String listAmountDisplay;
  final String discountDisplay;
  final String payableDisplay;
  final int tier;
  final String pricingMode;

  bool get isFree => payableCents <= 0;

  factory PackageQuote.fromJson(Map<String, dynamic> json) {
    return PackageQuote(
      listAmountCents: (json['list_amount_cents'] as num?)?.toInt() ?? 0,
      discountCents: (json['discount_cents'] as num?)?.toInt() ?? 0,
      payableCents: (json['payable_cents'] as num?)?.toInt() ?? 0,
      discountPercent: (json['discount_percent'] as num?)?.toInt() ?? 0,
      pricingNote: (json['pricing_note'] as String?)?.trim() ?? '',
      listAmountDisplay:
          (json['list_amount_display'] as String?)?.trim() ?? '',
      discountDisplay: (json['discount_display'] as String?)?.trim() ?? '',
      payableDisplay: (json['payable_display'] as String?)?.trim() ?? '',
      tier: (json['tier'] as num?)?.toInt() ?? 0,
      pricingMode: (json['pricing_mode'] as String?)?.trim() ?? 'percent',
    );
  }
}

class PackageItem {
  const PackageItem({
    required this.itemId,
    required this.serviceId,
    required this.serviceSlug,
    required this.serviceName,
    required this.durationMinutes,
    required this.slotCount,
    required this.priceDisplay,
    required this.durationDisplay,
    this.categoryName = '',
    this.price = '',
  });

  final int itemId;
  final int serviceId;
  final String serviceSlug;
  final String serviceName;
  final int durationMinutes;
  final int slotCount;
  final String priceDisplay;
  final String durationDisplay;
  final String categoryName;
  final String price;

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    return PackageItem(
      itemId: (json['item_id'] as num?)?.toInt() ?? 0,
      serviceId: (json['service_id'] as num?)?.toInt() ?? 0,
      serviceSlug: (json['service_slug'] as String?)?.trim() ?? '',
      serviceName: (json['service_name'] as String?)?.trim() ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      slotCount: (json['slot_count'] as num?)?.toInt() ?? 1,
      priceDisplay: (json['price_display'] as String?)?.trim() ?? '',
      durationDisplay: (json['duration_display'] as String?)?.trim() ?? '',
      categoryName: (json['category_name'] as String?)?.trim() ?? '',
      price: (json['price'] as String?)?.trim() ?? '',
    );
  }
}

class PackageAuthPrefill {
  const PackageAuthPrefill({
    this.isAuthenticated = false,
    this.fullName = '',
    this.email = '',
    this.phone = '',
  });

  final bool isAuthenticated;
  final String fullName;
  final String email;
  final String phone;

  factory PackageAuthPrefill.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PackageAuthPrefill();
    return PackageAuthPrefill(
      isAuthenticated: json['is_authenticated'] == true,
      fullName: (json['full_name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
    );
  }
}

class PackageBundle {
  const PackageBundle({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.items,
    required this.quote,
    this.tiers = const [],
    this.auth = const PackageAuthPrefill(),
    this.packageWindowDays = 180,
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final List<PackageItem> items;
  final PackageQuote quote;
  final List<PackageQuote> tiers;
  final PackageAuthPrefill auth;
  final int packageWindowDays;

  factory PackageBundle.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? const [];
    final tiersRaw = json['tiers'] as List<dynamic>? ?? const [];
    final quoteRaw = json['quote'];
    return PackageBundle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
      slug: (json['slug'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      items: itemsRaw
          .whereType<Map>()
          .map((e) => PackageItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      quote: PackageQuote.fromJson(
        quoteRaw is Map
            ? Map<String, dynamic>.from(quoteRaw)
            : const <String, dynamic>{},
      ),
      tiers: tiersRaw
          .whereType<Map>()
          .map((e) => PackageQuote.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      auth: PackageAuthPrefill.fromJson(
        json['auth'] is Map
            ? Map<String, dynamic>.from(json['auth'] as Map)
            : null,
      ),
      packageWindowDays:
          (json['package_window_days'] as num?)?.toInt() ?? 180,
    );
  }
}

class PackageCatalog {
  const PackageCatalog({
    required this.results,
    this.viewerTier = 0,
    this.packageWindowDays = 180,
  });

  final List<PackageBundle> results;
  final int viewerTier;
  final int packageWindowDays;

  factory PackageCatalog.fromJson(Map<String, dynamic> json) {
    final raw = json['results'] as List<dynamic>? ?? const [];
    return PackageCatalog(
      viewerTier: (json['viewer_tier'] as num?)?.toInt() ?? 0,
      packageWindowDays:
          (json['package_window_days'] as num?)?.toInt() ?? 180,
      results: raw
          .whereType<Map>()
          .map((e) => PackageBundle.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class PackageSelection {
  const PackageSelection({
    required this.itemId,
    required this.date,
    required this.timeMinutes,
  });

  final int itemId;
  final DateTime date;
  final int timeMinutes;

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'date': dateKey,
        'time_minutes': timeMinutes,
      };
}

class PackageBookingResult {
  const PackageBookingResult({
    required this.purchaseId,
    required this.appointmentIds,
    required this.status,
    required this.message,
    this.pointsAwarded = 0,
  });

  final int purchaseId;
  final List<int> appointmentIds;
  final String status;
  final String message;
  final int pointsAwarded;

  factory PackageBookingResult.fromJson(Map<String, dynamic> json) {
    final ids = json['appointment_ids'] as List<dynamic>? ?? const [];
    return PackageBookingResult(
      purchaseId: (json['purchase_id'] as num?)?.toInt() ?? 0,
      appointmentIds: ids
          .map((e) => (e as num?)?.toInt() ?? 0)
          .where((e) => e > 0)
          .toList(),
      status: (json['status'] as String?)?.trim() ?? '',
      message: (json['message'] as String?)?.trim() ?? '',
      pointsAwarded: (json['points_awarded'] as num?)?.toInt() ?? 0,
    );
  }
}

class PackagePaymentSession {
  const PackagePaymentSession({
    required this.paymentSessionId,
    required this.clientSecret,
    required this.amountCents,
    required this.amountDisplay,
    this.provider = 'mock',
    this.payableDisplay = '',
    this.pricingNote = '',
  });

  final String paymentSessionId;
  final String clientSecret;
  final int amountCents;
  final String amountDisplay;
  final String provider;
  final String payableDisplay;
  final String pricingNote;

  factory PackagePaymentSession.fromJson(Map<String, dynamic> json) {
    return PackagePaymentSession(
      paymentSessionId:
          (json['payment_session_id'] as String?)?.trim() ?? '',
      clientSecret: (json['client_secret'] as String?)?.trim() ?? '',
      amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
      amountDisplay: (json['amount_display'] as String?)?.trim() ?? '',
      provider: (json['provider'] as String?)?.trim() ?? 'mock',
      payableDisplay: (json['payable_display'] as String?)?.trim() ?? '',
      pricingNote: (json['pricing_note'] as String?)?.trim() ?? '',
    );
  }
}
