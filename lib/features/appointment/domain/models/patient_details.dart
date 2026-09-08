class PatientDetails {
  const PatientDetails({
    required this.name,
    required this.email,
    required this.phone,
    this.notes = '',
  });

  final String name;
  final String email;
  final String phone;
  final String notes;

  factory PatientDetails.fromJson(Map<String, dynamic> json) {
    return PatientDetails(
      name: (json['name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      notes: (json['notes'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'notes': notes,
      };

  PatientDetails copyWith({
    String? name,
    String? email,
    String? phone,
    String? notes,
  }) {
    return PatientDetails(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
    );
  }
}
