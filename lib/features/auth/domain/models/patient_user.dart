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
  final bool membershipActive;
  final bool canBookForFamily;
  final DateTime? membershipExpiresAt;

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

  factory PatientUser.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json['membership_expires_at'];
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
      membershipActive: json['membership_active'] == true,
      canBookForFamily: json['can_book_for_family'] == true,
      membershipExpiresAt: expiresRaw is String && expiresRaw.isNotEmpty
          ? DateTime.tryParse(expiresRaw)
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
        'membership_active': membershipActive,
        'can_book_for_family': canBookForFamily,
        'membership_expires_at': membershipExpiresAt?.toIso8601String(),
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
