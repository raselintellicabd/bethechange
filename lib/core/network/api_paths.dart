/// Canonical REST paths used by repositories.
///
/// Mock mode serves these from local JSON via [MockApiInterceptor].
/// When Django DRF is ready, the same paths hit [EnvConfig.apiBaseUrl].
class ApiPaths {
  ApiPaths._();

  static const String about = '/about';
  static const String conditions = '/api/v1/conditions';
  static const String services = '/api/v1/services';
  static const String blog = '/api/v1/blog';
  static const String faq = '/api/v1/faq';
  static const String clinic = '/clinic';
  static const String home = '/api/v1/home';
  static const String doctors = '/api/v1/doctors';
  static const String patients = '/patients';
  static const String contact = '/api/v1/contact';
  static const String chatbotMessage = '/chatbot/message';
  static const String chatbotConfig = '/chatbot/config';

  /// Website calendar/slot map (same JSON as the public appointments page).
  static const String appointmentsAvailability = '/appointments/availability/';

  /// Public pending booking create (DRF).
  static const String appointments = '/api/v1/appointments/';

  static String condition(String id) => '$conditions/$id';
  static String service(String id) => '$services/$id';
  static String blogArticle(String id) => '$blog/$id';
  static String doctor(String slug) => '$doctors/$slug';
}
