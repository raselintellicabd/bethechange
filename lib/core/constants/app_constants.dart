class AppConstants {
  AppConstants._();

  static const String appTitle = 'BeTheChange';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Query param required when opening the Appointment screen.
  static const String sourceContextQueryParam = 'sourceContext';

  /// Patient Portal (external browser).
  static const String patientPortalUrl =
      'https://be-the-change-portal.md-hq.com/';

  /// Fullscript shop (external browser). Double-slash matches the live site.
  static const String shopSupplementsUrl =
      'https://us.fullscript.com//welcome/safrooz';

  /// Clinic contact facts (Phase J). Hours pending stakeholder confirm.
  static const String clinicName = 'Be The Change Health & Wellness Center';
  static const String clinicAddressLine1 = '8808 Centre Park Drive, Suite 301';
  static const String clinicAddressLine2 = 'Columbia, MD 21045';
  static const String clinicPhoneDisplay = '301-970-9724';
  static const String clinicPhoneTel = 'tel:3019709724';
  static const String clinicFaxDisplay = '301-359-1986';
  static const String clinicHours =
      'Monday–Friday (call to confirm today’s hours)';
}
