class MembershipUpgradeSuggestion {
  const MembershipUpgradeSuggestion({
    required this.message,
    required this.nextTier,
    required this.nextTitle,
    this.currentTier,
    this.currentTitle,
  });

  final String message;
  final int nextTier;
  final String nextTitle;
  final int? currentTier;
  final String? currentTitle;

  String get ctaLabel => 'View $nextTitle';

  factory MembershipUpgradeSuggestion.fromJson(Map<String, dynamic> json) {
    return MembershipUpgradeSuggestion(
      message: (json['message'] as String?)?.trim() ?? '',
      nextTier: (json['next_tier'] as num?)?.toInt() ?? 0,
      nextTitle: (json['next_title'] as String?)?.trim() ?? '',
      currentTier: (json['current_tier'] as num?)?.toInt(),
      currentTitle: (json['current_title'] as String?)?.trim(),
    );
  }
}

class PatientUser {
  const PatientUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.tier,
    required this.tierTitle,
    required this.leftDays,
    required this.servicesTaken,
    required this.complimentaryUsed,
    required this.membershipActive,
    required this.canBookForFamily,
    this.membershipExpiresAt,
    this.membershipStartedAt,
    this.complimentaryAllowance = 2,
    this.points = 0,
    this.upgradeSuggestion,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final int tier;
  final String tierTitle;
  final int leftDays;
  final int servicesTaken;
  final int complimentaryUsed;
  final int complimentaryAllowance;
  final int points;
  final bool membershipActive;
  final bool canBookForFamily;
  final DateTime? membershipExpiresAt;
  final DateTime? membershipStartedAt;
  final MembershipUpgradeSuggestion? upgradeSuggestion;

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? email : name;
  }

  String get initials {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isNotEmpty && l.isNotEmpty) {
      return '${f[0]}${l[0]}'.toUpperCase();
    }
    if (f.isNotEmpty) return f[0].toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  bool get profileComplete =>
      fullName.isNotEmpty && email.isNotEmpty && phone.trim().isNotEmpty;

  PatientUser copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    int? tier,
    String? tierTitle,
    int? leftDays,
    int? servicesTaken,
    int? complimentaryUsed,
    int? complimentaryAllowance,
    int? points,
    bool? membershipActive,
    bool? canBookForFamily,
    DateTime? membershipExpiresAt,
    DateTime? membershipStartedAt,
    MembershipUpgradeSuggestion? upgradeSuggestion,
  }) {
    return PatientUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      tier: tier ?? this.tier,
      tierTitle: tierTitle ?? this.tierTitle,
      leftDays: leftDays ?? this.leftDays,
      servicesTaken: servicesTaken ?? this.servicesTaken,
      complimentaryUsed: complimentaryUsed ?? this.complimentaryUsed,
      complimentaryAllowance:
          complimentaryAllowance ?? this.complimentaryAllowance,
      points: points ?? this.points,
      membershipActive: membershipActive ?? this.membershipActive,
      canBookForFamily: canBookForFamily ?? this.canBookForFamily,
      membershipExpiresAt: membershipExpiresAt ?? this.membershipExpiresAt,
      membershipStartedAt: membershipStartedAt ?? this.membershipStartedAt,
      upgradeSuggestion: upgradeSuggestion ?? this.upgradeSuggestion,
    );
  }

  factory PatientUser.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json['membership_expires_at'];
    final startedRaw = json['membership_started_at'];
    final upgradeRaw = json['upgrade_suggestion'];
    return PatientUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: (json['email'] as String?)?.trim() ?? '',
      firstName: (json['first_name'] as String?)?.trim() ?? '',
      lastName: (json['last_name'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      tier: (json['tier'] as num?)?.toInt() ?? 0,
      tierTitle: (json['tier_title'] as String?)?.trim() ?? 'Free',
      leftDays: (json['left_days'] as num?)?.toInt() ?? 0,
      servicesTaken: (json['services_taken'] as num?)?.toInt() ?? 0,
      complimentaryUsed: (json['complimentary_used'] as num?)?.toInt() ?? 0,
      complimentaryAllowance:
          (json['complimentary_allowance'] as num?)?.toInt() ?? 2,
      points: (json['points'] as num?)?.toInt() ?? 0,
      membershipActive: json['membership_active'] == true,
      canBookForFamily: json['can_book_for_family'] == true,
      membershipExpiresAt: expiresRaw is String && expiresRaw.isNotEmpty
          ? DateTime.tryParse(expiresRaw)
          : null,
      membershipStartedAt: startedRaw is String && startedRaw.isNotEmpty
          ? DateTime.tryParse(startedRaw)
          : null,
      upgradeSuggestion: upgradeRaw is Map
          ? MembershipUpgradeSuggestion.fromJson(
              Map<String, dynamic>.from(upgradeRaw),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'tier': tier,
        'tier_title': tierTitle,
        'left_days': leftDays,
        'services_taken': servicesTaken,
        'complimentary_used': complimentaryUsed,
        'complimentary_allowance': complimentaryAllowance,
        'points': points,
        'membership_active': membershipActive,
        'can_book_for_family': canBookForFamily,
        'membership_expires_at': membershipExpiresAt?.toIso8601String(),
        'membership_started_at': membershipStartedAt?.toIso8601String(),
        if (upgradeSuggestion != null)
          'upgrade_suggestion': {
            'message': upgradeSuggestion!.message,
            'next_tier': upgradeSuggestion!.nextTier,
            'next_title': upgradeSuggestion!.nextTitle,
            'current_tier': upgradeSuggestion!.currentTier,
            'current_title': upgradeSuggestion!.currentTitle,
          },
      };
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final PatientUser user;
}
