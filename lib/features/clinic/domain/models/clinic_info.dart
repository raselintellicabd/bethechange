class ClinicInfo {
  const ClinicInfo({
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.phoneDisplay,
    required this.phoneTel,
    required this.faxDisplay,
    required this.hours,
    required this.patientPortalUrl,
    required this.shopSupplementsUrl,
  });

  final String name;
  final String addressLine1;
  final String addressLine2;
  final String phoneDisplay;
  final String phoneTel;
  final String faxDisplay;
  final String hours;
  final String patientPortalUrl;
  final String shopSupplementsUrl;

  String get fullAddress => '$addressLine1, $addressLine2';

  factory ClinicInfo.fromJson(Map<String, dynamic> json) {
    return ClinicInfo(
      name: (json['name'] as String?)?.trim() ?? '',
      addressLine1: (json['addressLine1'] as String?)?.trim() ?? '',
      addressLine2: (json['addressLine2'] as String?)?.trim() ?? '',
      phoneDisplay: (json['phoneDisplay'] as String?)?.trim() ?? '',
      phoneTel: (json['phoneTel'] as String?)?.trim() ?? '',
      faxDisplay: (json['faxDisplay'] as String?)?.trim() ?? '',
      hours: (json['hours'] as String?)?.trim() ?? '',
      patientPortalUrl: (json['patientPortalUrl'] as String?)?.trim() ?? '',
      shopSupplementsUrl: (json['shopSupplementsUrl'] as String?)?.trim() ?? '',
    );
  }

  String? urlForKey(String key) {
    return switch (key) {
      'patientPortalUrl' => patientPortalUrl,
      'shopSupplementsUrl' => shopSupplementsUrl,
      _ => null,
    };
  }
}
