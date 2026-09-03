abstract final class AppRoutes {
  static const String about = '/about';
  static const String conditions = '/conditions';
  static const String conditionDetail = '/conditions/:conditionId';
  static const String services = '/services';
  static const String serviceDetail = '/services/:serviceId';
  static const String blog = '/blog';
  static const String blogDetail = '/blog/:articleId';
  static const String patient = '/patient';
  static const String appointment = '/appointment';
  static const String faq = '/faq';
  static const String contact = '/contact';

  static String conditionDetailPath(String conditionId) =>
      '/conditions/$conditionId';

  static String serviceDetailPath(String serviceId) => '/services/$serviceId';

  static String blogDetailPath(String articleId) => '/blog/$articleId';

  /// Appointment must always be opened with a [sourceContext] query param.
  static String appointmentPath(String sourceContext) =>
      '/appointment?sourceContext=${Uri.encodeQueryComponent(sourceContext)}';
}
