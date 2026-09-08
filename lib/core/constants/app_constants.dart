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
}
