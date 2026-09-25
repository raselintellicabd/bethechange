class PointOfferAuthPrefill {
  const PointOfferAuthPrefill({
    required this.isAuthenticated,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  final bool isAuthenticated;
  final String fullName;
  final String email;
  final String phone;

  factory PointOfferAuthPrefill.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PointOfferAuthPrefill(
        isAuthenticated: false,
        fullName: '',
        email: '',
        phone: '',
      );
    }
    return PointOfferAuthPrefill(
      isAuthenticated: json['is_authenticated'] == true,
      fullName: (json['full_name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
    );
  }
}

class PointOffer {
  const PointOffer({
    required this.id,
    required this.serviceId,
    required this.serviceSlug,
    required this.serviceName,
    required this.categoryName,
    required this.durationMinutes,
    required this.durationDisplay,
    required this.slotCount,
    required this.listPrice,
    required this.listPriceDisplay,
    required this.requiredPoints,
    required this.canClaim,
    this.categorySlug = '',
    this.pricingNote = '',
    this.payableDisplay = '',
    this.pointsBalance,
    this.auth = const PointOfferAuthPrefill(
      isAuthenticated: false,
      fullName: '',
      email: '',
      phone: '',
    ),
  });

  final int id;
  final int serviceId;
  final String serviceSlug;
  final String serviceName;
  final String categoryName;
  final String categorySlug;
  final int durationMinutes;
  final String durationDisplay;
  final int slotCount;
  final String listPrice;
  final String listPriceDisplay;
  final int requiredPoints;
  final bool canClaim;
  final String pricingNote;
  final String payableDisplay;
  final int? pointsBalance;
  final PointOfferAuthPrefill auth;

  factory PointOffer.fromJson(Map<String, dynamic> json) {
    return PointOffer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      serviceId: (json['service_id'] as num?)?.toInt() ?? 0,
      serviceSlug: (json['service_slug'] as String?)?.trim() ?? '',
      serviceName: (json['service_name'] as String?)?.trim() ?? '',
      categoryName: (json['category_name'] as String?)?.trim() ?? '',
      categorySlug: (json['category_slug'] as String?)?.trim() ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      durationDisplay: (json['duration_display'] as String?)?.trim() ?? '',
      slotCount: (json['slot_count'] as num?)?.toInt() ?? 1,
      listPrice: '${json['list_price'] ?? ''}',
      listPriceDisplay: (json['list_price_display'] as String?)?.trim() ?? '',
      requiredPoints: (json['required_points'] as num?)?.toInt() ?? 0,
      canClaim: json['can_claim'] == true,
      pricingNote: (json['pricing_note'] as String?)?.trim() ?? '',
      payableDisplay: (json['payable_display'] as String?)?.trim() ?? '',
      pointsBalance: (json['points_balance'] as num?)?.toInt(),
      auth: PointOfferAuthPrefill.fromJson(
        json['auth'] is Map
            ? Map<String, dynamic>.from(json['auth'] as Map)
            : null,
      ),
    );
  }
}

class PointOfferCatalog {
  const PointOfferCatalog({
    required this.results,
    this.pointsBalance,
  });

  final List<PointOffer> results;
  final int? pointsBalance;

  factory PointOfferCatalog.fromJson(Map<String, dynamic> json) {
    final raw = json['results'];
    final results = <PointOffer>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          results.add(
            PointOffer.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return PointOfferCatalog(
      results: results,
      pointsBalance: (json['points_balance'] as num?)?.toInt(),
    );
  }
}

class PointOfferClaimResult {
  const PointOfferClaimResult({
    required this.id,
    required this.status,
    required this.pointsSpent,
    required this.message,
    this.pointsBalance,
  });

  final int id;
  final String status;
  final int pointsSpent;
  final int? pointsBalance;
  final String message;

  factory PointOfferClaimResult.fromJson(Map<String, dynamic> json) {
    return PointOfferClaimResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?)?.trim() ?? '',
      pointsSpent: (json['points_spent'] as num?)?.toInt() ?? 0,
      pointsBalance: (json['points_balance'] as num?)?.toInt(),
      message: (json['message'] as String?)?.trim() ?? '',
    );
  }
}
