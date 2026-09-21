import 'consultation_mode.dart';

class PatientDetails {
  const PatientDetails({
    required this.name,
    required this.email,
    required this.phone,
    required this.consultationMode,
    this.forFamilyMember = false,
  });

  final String name;
  final String email;
  final String phone;
  final ConsultationMode consultationMode;
  final bool forFamilyMember;

  factory PatientDetails.fromJson(Map<String, dynamic> json) {
    final mode = ConsultationMode.tryParse(
          json['consultation_mode'] as String? ??
              json['consultationMode'] as String?,
        ) ??
        ConsultationMode.virtual;
    return PatientDetails(
      name: (json['name'] as String?)?.trim() ??
          (json['full_name'] as String?)?.trim() ??
          '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      consultationMode: mode,
      forFamilyMember: json['for_family_member'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'consultation_mode': consultationMode.apiValue,
        'for_family_member': forFamilyMember,
      };

  PatientDetails copyWith({
    String? name,
    String? email,
    String? phone,
    ConsultationMode? consultationMode,
    bool? forFamilyMember,
  }) {
    return PatientDetails(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      consultationMode: consultationMode ?? this.consultationMode,
      forFamilyMember: forFamilyMember ?? this.forFamilyMember,
    );
  }
}
