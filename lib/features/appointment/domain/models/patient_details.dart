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
